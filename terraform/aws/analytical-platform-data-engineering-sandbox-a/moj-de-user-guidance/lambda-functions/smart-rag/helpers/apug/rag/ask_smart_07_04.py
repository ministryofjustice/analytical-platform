"""
Smart RAG Answer Generation Module

This module implements the final stages of the Smart RAG pipeline: answer generation,
validation, and orchestration. It combines retrieved documents with LLM-based generation
to produce high-quality answers with inline citations and confidence scores.

Key Components:
--------------
1. **SmartAnswer**: Dataclass containing complete answer with metadata and quality indicators
2. **KnowledgeBaseRetriever**: Direct interface to AWS Bedrock Knowledge Base retrieval
3. **AnswerGenerator**: LLM-based answer generation with validation and confidence scoring
4. **AskSmart**: Orchestrator that integrates all pipeline stages into a single interface

Architecture Overview:
--------------------
┌─────────────────────────────────────────────────────────────────────┐
│                         AskSmart Pipeline                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ask(query) ──┐                                                     │
│               │                                                     │
│               ├──► 1. QueryAnalyser.analyse()                      │
│               │      └─► Extract intent, entities, context         │
│               │                                                     │
│               ├──► 2. RetrievalPlanner.plan()                      │
│               │      └─► Determine strategy & fallback ladder      │
│               │                                                     │
│               ├──► 3. FilterGenerator.generate_and_retrieve()      │
│               │      ├─► LLM filter refinement                     │
│               │      ├─► Execute retrieval with filters            │
│               │      └─► Progressive fallback if needed            │
│               │                                                     │
│               ├──► 4. AnswerGenerator.generate()                   │
│               │      ├─► Build context from documents              │
│               │      ├─► Generate answer with citations            │
│               │      └─► Calculate confidence score                │
│               │                                                     │
│               ├──► 5. AnswerGenerator.validate()                   │
│               │      └─► Check quality and detect issues           │
│               │                                                     │
│               └──► 6. Package SmartAnswer                          │
│                      └─► Complete response with metadata           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

SmartAnswer Structure:
--------------------
The complete response object returned by ask_smart() containing:

- **answer**: Generated answer text with inline [Doc N] citations
- **sources**: Top 3 source documents with:
  - content preview (first 300 chars)
  - full metadata (page_h1, root_heading, etc.)
  - relevance score
  - source location
- **retrieval_metadata**: Full pipeline trace including:
  - strategy used (e.g., "PRECISE", "BROAD_EXPLORATION_fallback_2")
  - filters applied at each step
  - fallback depth (0 = initial, 1-4 = ladder steps)
  - document count retrieved
  - analyzer confidence
  - query classification
  - tools/entities mentioned
  - total latency in milliseconds
- **confidence**: Multi-factor score (0.0-1.0) based on:
  - Top document relevance score (35%)
  - Score consistency across results (15%)
  - Document coverage (15%)
  - Answer specificity (10%)
  - Refusal detection penalty (15%)
  - Query-answer alignment (10%)
- **validation_issues**: List of detected quality problems:
  - Answer too short
  - Potential hallucination
  - Off-topic content
  - Excessive uncertainty

KnowledgeBaseRetriever:
---------------------
Simplified wrapper around AWS Bedrock Knowledge Base API with:

**Filter Translation**:
  Simple dict → AWS structure
  {"page_h1": "RStudio"} → {"equals": {"key": "page_h1", "value": "RStudio"}}
  {"page_h1": ["RStudio", "Python"]} → {"in": {"key": "page_h1", "value": [...]}}

**Error Handling**:
  - ResourceNotFoundException → Clear "KB not found" message
  - ValidationException → "Invalid configuration" message
  - ThrottlingException → Retry signal for upstream
  - Generic errors → Wrapped with context

**Result Format**:
  Each document contains:
  - content: Full text chunk
  - metadata: All metadata fields (page_h1, root_heading, etc.)
  - score: Semantic similarity score (0.0-1.0)
  - location: S3 URI and chunk reference

AnswerGenerator:
--------------
LLM-based answer generation with quality assurance:

**Context Building**:
  - Token-aware document packing (default: 6000 tokens max)
  - Smart truncation preserving document headers
  - Formatted sources with metadata attribution
  - Automatic overflow handling

**Generation Process**:
  1. Build context from retrieved documents
  2. Construct prompt with citation instructions
  3. Call Claude via Bedrock Runtime API
  4. Extract answer from response blocks
  5. Calculate multi-factor confidence score
  6. Return (answer_text, confidence)

**Confidence Calculation**:
  Multi-factor weighted score combining:
  - **Top Score** (35%): Best document's relevance
  - **Consistency** (15%): Low variance across top 5 scores
  - **Coverage** (15%): Number of documents retrieved
  - **Specificity** (10%): Answer length vs. expected (120 words)
  - **Refusal** (15%): Penalty for "cannot answer" patterns
  - **Alignment** (10%): Query-answer keyword overlap

**Validation Checks**:
  - Minimum length (10 words)
  - Hallucination markers ("as an AI", "I don't have access")
  - Topic alignment (keyword overlap)
  - Uncertainty markers ("unclear", "not sure", "might be")

**Retry Logic**:
  - Automatic retry for throttling errors (exponential backoff)
  - Max 3 attempts by default
  - Graceful degradation on persistent failures

**Token Management**:
  - Simple word-based estimation (word_count * 1.3)
  - Progressive document truncation when over budget
  - Preserves document attribution even when truncated

AskSmart Orchestrator:
--------------------
Main entry point that coordinates the entire pipeline:

**Responsibilities**:
  1. Query analysis orchestration
  2. Retrieval planning coordination
  3. Filter generation and retrieval execution
  4. Answer generation with context
  5. Quality validation
  6. Result packaging with full metadata
  7. Error handling and fallback

**Initialization**:
  Requires pre-initialized components:
  - QueryAnalyser (intent extraction)
  - RetrievalPlanner (strategy selection)
  - FilterGenerator (retrieval execution)
  - KB catalog (available metadata values)

**Output Structure**:
  Returns SmartAnswer with complete provenance:
  - What was retrieved (docs + metadata)
  - How it was retrieved (strategy + filters)
  - Why fallbacks occurred (step trace)
  - Quality indicators (confidence + validation)
  - Performance metrics (latency)


"""

from dataclasses import dataclass
from typing import Dict, Any, List, Tuple
import boto3
import json
import time
import random
import numpy as np, re, traceback
from botocore.exceptions import ClientError
from dataclasses import field
from config import MODEL_ID, REGION

# Import your MoJ system prompt
from config import SYSTEM_PROMPT


# ----------------------------
# Data clasees
# ----------------------------
@dataclass
class SmartAnswer:
    """
    Complete response from ask_smart().
    
    Attributes:
        answer (str): Generated answer text with inline citations
        sources (List[Dict]): Source documents used
        retrieval_metadata (Dict): Debugging info (strategy, filters, fallback step)
        confidence (float): Overall confidence in answer
        validation_issues (List[str]): Any quality concerns detected
    """
    answer: str
    sources: List[Dict[str, Any]]
    retrieval_metadata: Dict[str, Any]
    confidence: float
    validation_issues: List[str] = field(default_factory=list)


# ----------------------------
# AskSmart orchestration class
# ----------------------------
# We follow the below order
# -----------------------------------------
# KnowledgeBaseRetriever
#  - retrieve()
#  - _build_kb_filter()
#  - flatten_plan_filters()
# ----------------------------------------
# AnswerGenerator
#   - generate()
#   - validate()
#   - _build_context()
#   - _build_conversation_context()
#   - _calculate_confidence()
#   - _detect_refusal()
#   - _estimate_tokens()
#   - _truncate_to_tokens()
# ----------------------------------------
# AskSmart
# - ask()  # Just orchestrates the above classes
# - _create_smart_answer()
# - _handle_error()
# - _print_header()
# - _print_summary()
# ----------------------------------------

## 1. **KnowledgeBaseRetriever** (KB Operations)

class KnowledgeBaseRetriever:
    """Handles all AWS Bedrock Knowledge Base retrieval operations."""
    
    def __init__(self, kb_id: str, region: str = REGION):
        self.kb_id = kb_id
        self.region = region
        self.bedrock_agent = boto3.client("bedrock-agent-runtime", region_name=region)
    
    def retrieve(self, 
                query: str, 
                filters: Dict[str, Any] = None,
                top_k: int = 5,
                verbose: bool = False) -> List[Dict]:
        """
        Retrieve documents from KB with optional filters.
        
        Args:
            query: Search query text
            filters: Simple key-value filter dict (e.g., {"page_h1": "RStudio"})
            top_k: Number of results to retrieve
            verbose: Enable logging
            
        Returns:
            List of documents with content, metadata, score, location
        """
        try:
            kb_filter = self._build_kb_filter(filters) if filters else {}
            
            if verbose:
                print(f" Querying KB: {self.kb_id}")
                print(f" Filters: {json.dumps(filters, indent=2) if filters else 'None'}")
                print(f" Top K: {top_k}")
            
            retrieval_config = {
                'vectorSearchConfiguration': {
                    'numberOfResults': top_k
                }
            }
            
            if kb_filter:
                retrieval_config['vectorSearchConfiguration']['filter'] = kb_filter
            
            response = self.bedrock_agent.retrieve(
                knowledgeBaseId=self.kb_id,
                retrievalQuery={'text': query},
                retrievalConfiguration=retrieval_config
            )
            
            documents = []
            for result in response.get('retrievalResults', []):
                doc = {
                    'content': result['content']['text'],
                    'metadata': result.get('metadata', {}),
                    'score': result.get('score', 0.0),
                    'location': result.get('location', {})
                }
                documents.append(doc)
            
            if verbose:
                print(f"Retrieved {len(documents)} documents")
                if documents:
                    print(f"Top score: {documents[0]['score']:.3f}")
            
            return documents
        
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_msg = e.response['Error']['Message']
            
            if verbose:
                print(f"KB retrieval failed: {error_code} - {error_msg}")
            
            if error_code == 'ResourceNotFoundException':
                raise ValueError(f"Knowledge Base not found: {self.kb_id}")
            elif error_code == 'ValidationException':
                raise ValueError(f"Invalid retrieval configuration: {error_msg}")
            elif error_code == 'ThrottlingException':
                raise Exception(f"KB retrieval throttled: {error_msg}")
            else:
                raise Exception(f"KB retrieval error: {error_code} - {error_msg}")
        
        except Exception as e:
            if verbose:
                print(f"Unexpected error during KB retrieval: {e}")
            raise
    
    def _build_kb_filter(self, filters: Dict[str, Any]) -> Dict:
        """
        Build AWS KB filter structure from simple key-value pairs.
        
        Args:
            filters: Simple dict like {"page_h1": "RStudio", "root_heading": ["Install", "Setup"]}
            
        Returns:
            AWS Bedrock filter structure
        """
        if not filters:
            return {}
        
        filter_conditions = []
        
        for key, value in filters.items():
            if value:
                if isinstance(value, list):
                    filter_conditions.append({
                        "in": {
                            "key": key,
                            "value": value
                        }
                    })
                else:
                    filter_conditions.append({
                        "equals": {
                            "key": key,
                            "value": value
                        }
                    })
        
        if not filter_conditions:
            return {}
        
        return {"andAll": filter_conditions} if len(filter_conditions) > 1 else filter_conditions[0]


## 2. **AnswerGenerator** (Answer Generation, Validation, Confidence)

class AnswerGenerator:
    """Generates and validates answers using LLM with confidence scoring."""
    
    def __init__(self, 
                 model_id: str = MODEL_ID,
                 region: str = REGION,
                 max_context_tokens: int = 6000):
        self.model_id = model_id
        self.region = region
        self.max_context_tokens = max_context_tokens
        self.bedrock_runtime = boto3.client("bedrock-runtime", region_name=region)
    
    # ----------------------------- Public API ----------------------------- #
    
    def generate(self,
                query: str,
                documents: List[Dict],
                max_retries: int = 3,
                verbose: bool = False) -> Tuple[str, float]:
        """
        Generate answer from documents with confidence score.
        
        Args:
            query: User query
            documents: Retrieved documents
            max_retries: Number of retry attempts for transient failures
            verbose: Enable logging
            
        Returns:
            Tuple of (answer_text, confidence_score)
        """
        if not documents:
            return (
                "No relevant documentation found for your query. "
                "Please contact the Analytical Platform support team for assistance.",
                0.0
            )
        
        # Build document context with token management
        doc_context = self._build_context(documents)
        
        # Construct user message with citation instructions
        user_message = f"""**Retrieved Context:**

{doc_context}

---

**User Question:**
{query}

**Instructions:**
1. Answer ONLY based on the retrieved context above
2. **Cite sources inline** using [Doc N] notation (e.g., "According to [Doc 1], ...")
3. If information spans multiple sources, cite all relevant documents
4. If the context doesn't contain sufficient information to fully answer, clearly state what's missing
5. Be specific and provide actionable information when available

Provide your answer with inline citations:"""
        
        # Retry loop for handling transient failures
        for attempt in range(max_retries):
            try:
                if verbose:
                    print(f"Generating answer (attempt {attempt + 1}/{max_retries})...")
                
                request = {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 2048,
                    "temperature": 0.1,
                    "system": SYSTEM_PROMPT,
                    "messages": [
                        {
                            "role": "user",
                            "content": [{"type": "text", "text": user_message}]
                        }
                    ],
                    "stop_sequences": []
                }
                
                response = self.bedrock_runtime.invoke_model(
                    modelId=self.model_id,
                    body=json.dumps(request)
                )
                
                payload = json.loads(response['body'].read())
                blocks = payload.get("content", [])
                
                answer = "\n".join(
                    block.get("text", "")
                    for block in blocks
                    if block.get("type") == "text"
                ).strip()
                
                # Calculate confidence
                confidence_result = self._calculate_confidence(query, answer, documents)
                confidence = confidence_result["confidence"]
                
                if verbose:
                    print(f"Answer generated (confidence: {confidence:.2f})")
                    print(f"Confidence factors: {confidence_result['factors']}")
                
                return answer, confidence
            
            except ClientError as e:
                error_code = e.response['Error']['Code']
                
                if error_code in ['ThrottlingException', 'TooManyRequestsException']:
                    if attempt < max_retries - 1:
                        wait_time = (2 ** attempt) + (random.random() * 0.1)
                        if verbose:
                            print(f"⚠️  Throttled. Retrying in {wait_time:.1f}s...")
                        time.sleep(wait_time)
                        continue
                    else:
                        return "Service is temporarily busy. Please try again in a moment.", 0.0
                
                elif error_code in ['ValidationException', 'ModelNotReadyException']:
                    if verbose:
                        print(f"Model error: {error_code}")
                    return f"Model configuration error. Please contact support.", 0.0
                
                elif attempt < max_retries - 1:
                    if verbose:
                        print(f"⚠️  AWS error: {error_code}. Retrying...")
                    time.sleep(1)
                    continue
                else:
                    return f"Service error: {error_code}. Please try again later.", 0.0
            
            except json.JSONDecodeError as e:
                if verbose:
                    print(f"JSON parsing error: {e}")
                return "Error processing response. Please try again.", 0.0
            
            except Exception as e:
                if verbose:
                    print(f"Unexpected error: {type(e).__name__}: {e}")
                    traceback.print_exc()
                
                if attempt < max_retries - 1:
                    time.sleep(1)
                    continue
                else:
                    return f"Unexpected error occurred. Please contact support.", 0.0
        
        return "Failed to generate answer after multiple retries. Please try again.", 0.0
    
    def validate(self, answer: str, query: str) -> Dict[str, Any]:
        """
        Validate answer quality and detect issues.
        
        Args:
            answer: Generated answer text
            query: Original user query
            
        Returns:
            Dict with is_valid, issues list, and word_count
        """
        issues = []
        answer_text = answer.lower()
        query_terms = set(re.findall(r"\w+", query.lower()))
        answer_terms = set(re.findall(r"\w+", answer_text))
        word_count = len(answer.split())
        
        hallucination_phrases = [
            r"\bas an ai\b", r"\bi don't have access\b",
            r"\bi cannot browse\b", r"\bas a language model\b",
            r"\bi'm not able to\b"
        ]
        
        uncertainty_markers = [
            r"\bunclear\b", r"\bnot sure\b", r"\bmight be\b",
            r"\bpossibly\b", r"\bmaybe\b"
        ]
        
        # Check 1: Minimum length
        if word_count < 10:
            issues.append("Answer too short (< 10 words)")
        
        # Check 2: Hallucination markers
        for pattern in hallucination_phrases:
            if re.search(pattern, answer_text):
                issues.append("Potential hallucination detected")
                break
        
        # Check 3: Off-topic check
        if len(query_terms & answer_terms) == 0 and word_count > 20:
            issues.append("Answer may be off-topic (no keyword overlap)")
        
        # Check 4: Excessive uncertainty
        uncertainty_count = sum(
            1 for marker in uncertainty_markers
            if re.search(marker, answer_text)
        )
        if uncertainty_count >= 3:
            issues.append("Excessive uncertainty markers detected")
        
        return {
            "is_valid": len(issues) == 0,
            "issues": issues,
            "word_count": word_count
        }
    
    # ------------------------- Context Building ------------------------- #
    
    def _build_context(self, documents: List[Dict], max_tokens: int = None) -> str:
        """
        Build formatted context from documents with token management.
        
        Args:
            documents: List of retrieved documents
            max_tokens: Maximum tokens (defaults to self.max_context_tokens)
            
        Returns:
            Formatted context string with document sources
        """
        if not documents:
            return "No documents retrieved."
        
        max_tokens = max_tokens or self.max_context_tokens
        context_parts, used = [], 0
        
        for i, doc in enumerate(documents, 1):
            metadata = doc.get('metadata', {})
            page_h1 = metadata.get('page_h1', 'Unknown')
            root_heading = metadata.get('root_heading', 'Unknown')
            content = doc.get('content', '')
            
            doc_header = (
                f"--- Document {i} ---\n"
                f"Source: {page_h1} > {root_heading}\n"
                f"Content:\n"
            )
            
            header_tokens = self._estimate_tokens(doc_header)
            content_tokens = self._estimate_tokens(content)
            doc_tokens = header_tokens + content_tokens
            
            if used + doc_tokens > max_tokens:
                remaining_tokens = max_tokens - used
                
                if remaining_tokens > 100:
                    truncated_content = self._truncate_to_tokens(
                        content,
                        remaining_tokens - header_tokens
                    )
                    context_parts.append(
                        f"--- Document {i} (truncated) ---\n"
                        f"Source: {page_h1} > {root_heading}\n"
                        f"Content:\n{truncated_content}\n"
                    )
                break
            
            context_parts.append(f"{doc_header}{content}\n")
            used += doc_tokens
        
        return "\n".join(context_parts)
    
    # ----------------------- Confidence Calculation ----------------------- #
    
    def _calculate_confidence(self,
                             query: str,
                             answer: str,
                             documents: List[Dict]) -> Dict[str, Any]:
        """
        Calculate multi-factor confidence score.
        
        Args:
            query: User query
            answer: Generated answer
            documents: Retrieved documents
            
        Returns:
            Dict with confidence score and individual factor scores
        """
        if not documents:
            return {"confidence": 0.0, "reason": "No documents retrieved"}
        
        # Factor 1: Top document score
        top_score = float(documents[0].get('score', 0.0))
        
        # Factor 2: Score consistency
        scores = [doc.get('score', 0.0) for doc in documents[:5]]
        if len(scores) > 1:
            score_variance = np.var(scores)
            consistency_factor = max(0.0, 1.0 - min(score_variance, 0.3))
        else:
            consistency_factor = 0.8
        
        # Factor 3: Document coverage
        doc_count_factor = min(len(documents) / 5.0, 1.0)
        
        # Factor 4: Answer specificity
        answer_length = len(answer.split())
        specificity_factor = min(answer_length / 120, 1.0)
        
        # Factor 5: Refusal detection
        refusal_score = self._detect_refusal(answer)
        
        # Factor 6: Query-answer alignment
        query_terms = set(re.findall(r"\w+", query.lower()))
        answer_terms = set(re.findall(r"\w+", answer.lower()))
        
        if len(query_terms) > 0:
            overlap_ratio = len(query_terms & answer_terms) / len(query_terms)
            alignment_factor = min(overlap_ratio * 2, 1.0)
        else:
            alignment_factor = 0.5
        
        # Weighted combination
        confidence = (
            top_score * 0.35 +
            consistency_factor * 0.15 +
            doc_count_factor * 0.15 +
            specificity_factor * 0.10 +
            (1 - refusal_score) * 0.15 +
            alignment_factor * 0.10
        )
        
        confidence = min(confidence, 0.95)
        
        return {
            "confidence": round(confidence, 3),
            "factors": {
                "top_score": round(top_score, 3),
                "consistency": round(consistency_factor, 3),
                "doc_count": round(doc_count_factor, 3),
                "specificity": round(specificity_factor, 3),
                "refusal_penalty": round(refusal_score, 3),
                "alignment": round(alignment_factor, 3)
            }
        }
    
    def _detect_refusal(self, answer: str) -> float:
        """
        Detect refusal patterns in answer.
        
        Args:
            answer: Generated answer text
            
        Returns:
            Refusal score (0.0-1.0, higher = more refusal detected)
        """
        refusal_patterns = {
            "strong": [
                r"\bcannot provide\b", r"\bno information available\b",
                r"\bunable to answer\b", r"\boutside my knowledge\b",
                r"\bi don't have access\b", r"\bi cannot\b"
            ],
            "moderate": [
                r"\bdoes not contain\b", r"\bnot documented\b",
                r"\bcontact support\b", r"\bplease reach out\b",
                r"\bno documented process\b"
            ],
            "weak": [
                r"\bunclear\b", r"\bambiguous\b", r"\bmay need to\b",
                r"\bnot entirely clear\b", r"\blimited information\b"
            ]
        }
        
        refusal_weights = {
            "strong": 0.8,
            "moderate": 0.5,
            "weak": 0.2
        }
        
        answer_lower = answer.lower()
        
        for level, patterns in refusal_patterns.items():
            for pattern in patterns:
                if re.search(pattern, answer_lower):
                    return refusal_weights[level]
        
        return 0.0
    
    # ------------------------- Token Management ------------------------- #
    
    @staticmethod
    def _estimate_tokens(text: str) -> int:
        """Estimate token count from text (simple word-based heuristic)."""
        word_count = len(text.split())
        return int(word_count * 1.3)
    
    def _truncate_to_tokens(self, text: str, max_tokens: int) -> str:
        """Truncate text to fit within token budget."""
        estimated_tokens = self._estimate_tokens(text)
        
        if estimated_tokens <= max_tokens:
            return text
        
        ratio = max_tokens / max(estimated_tokens, 1)
        words = text.split()
        truncated_words = words[:max(1, int(len(words) * ratio))]
        
        return " ".join(truncated_words) + "\n[...truncated for length...]"

## 3. **AskSmart** (Orchestration Layer)

class AskSmart:
    """
    Orchestrates the Smart RAG pipeline for intelligent question answering.
    
    Implements a multi-stage pipeline:
        1. Query Analysis - Extracts intent, entities, and context
        2. Retrieval Planning - Determines optimal search strategy
        3. Filter Generation & Retrieval - LLM-refined metadata filtering with fallback
        4. Answer Generation - Context-aware response with source citations
        5. Quality Validation - Confidence scoring and answer quality checks
    
    The pipeline automatically handles fallback strategies when initial retrieval
    is insufficient and provides detailed metadata for observability.
    
    Args:
        analyser: QueryAnalyser instance for intent extraction
        planner: RetrievalPlanner instance for strategy selection
        filter_gen: FilterGenerator instance for retrieval execution
        kb_id: AWS Bedrock Knowledge Base identifier
        kb_catalog: Available metadata values (page_h1, root_heading lists)
        answer_model_id: LLM model for answer generation (default: MODEL_ID)
        region: AWS region (default: REGION)
        max_context_tokens: Maximum tokens for document context (default: 6000)
    
    Example:
        >>> ask_smart = AskSmart(
        ...     analyser=query_analyser,
        ...     planner=retrieval_planner,
        ...     filter_gen=filter_generator,
        ...     kb_id="ABC123",
        ...     kb_catalog=catalog
        ... )
        >>> result = ask_smart.ask("How do I install RStudio?", verbose=True)
        >>> print(result.answer)
        >>> print(f"Confidence: {result.confidence}")
    """
    
    def __init__(self,
                 analyser,
                 planner,
                 filter_gen,
                 kb_id: str,
                 kb_catalog: Dict,
                 answer_model_id: str = MODEL_ID,
                 region: str = REGION,
                 max_context_tokens: int = 6000):
        
        self.analyser = analyser
        self.planner = planner
        self.filter_gen = filter_gen
        self.kb_id = kb_id
        self.kb_catalog = kb_catalog
        
        # Initialize specialized components
        self.answer_generator = AnswerGenerator(
            answer_model_id,
            region,
            max_context_tokens
        )
    
    # ----------------------------- Public API ----------------------------- #
    
    def ask(self,
            query: str,
            verbose: bool = False,
            logger=None) -> SmartAnswer:
        """
        Process a user query through the Smart RAG pipeline.
        
        Executes the full pipeline: analysis → planning → retrieval → generation → validation.
        Automatically handles retrieval fallbacks and provides detailed metadata for monitoring.
        
        Args:
            query: User's question
            verbose: Enable detailed logging of each pipeline stage
            logger: Optional SmartRAGLogger instance for observability
            
        Returns:
            SmartAnswer containing:
                - answer: Generated response with inline citations
                - sources: Top 3 source documents with metadata
                - retrieval_metadata: Strategy, filters, timing, confidence scores
                - confidence: Multi-factor confidence score (0.0-1.0)
                - validation_issues: List of detected quality issues (empty if valid)
        
        Example:
            >>> result = ask_smart.ask("How do I deploy to production?", verbose=True)
            >>> if result.confidence > 0.7:
            ...     print(result.answer)
            ... else:
            ...     print("Low confidence answer, review sources:", result.sources)
        """
        start_time = time.time()
        
        try:
            if verbose:
                self._print_header(query)
            
            # Step 1: Analyze query
            if verbose:
                print(" Step 1: Query Analysis...")
            analysis_start = time.time()
            analysis = self.analyser.analyse(query, verbose=verbose)
            if logger:
                logger.log_component(
                    "query_analysis",
                    duration_ms=(time.time() - analysis_start) * 1000,
                    metadata={
                        "intent": analysis.intent_primary.get("type", "unknown"),
                        "confidence": analysis.confidence_score,
                        "tools": analysis.tools_mentioned
                    }
                )
            
            # Step 2: Plan retrieval
            planning_start = time.time()
            if verbose:
                print("\n  Step 2: Retrieval Planning...")
            plan = self.planner.plan(analysis, kb_catalog=self.kb_catalog)
            if logger:
                logger.log_component(
                    "retrieval_planning",
                    duration_ms=(time.time() - planning_start) * 1000,
                    metadata={
                        "strategy": plan.initial_strategy,
                        "filters_allowed": plan.filters_allowed,
                        "top_k": plan.budget.top_k
                    }
                )
            if verbose:
                print(f"   Strategy: {plan.initial_strategy}")
                print(f"   Filters allowed: {plan.filters_allowed}")
                print(f"   Budget: top_k={plan.budget.top_k}, expansion={plan.budget.expansion}")
            
            # Step 3: Generate filters AND retrieve
            if verbose:
                print("\n Step 3: Filter Generation & Retrieval...")
            
            retrieval_start = time.time()
            retrieval_result = self.filter_gen.generate_and_retrieve(
                query=query,
                plan=plan,
                kb_catalog=self.kb_catalog,
                verbose=verbose
            )
            if logger:
                logger.log_component(
                    "retrieval",
                    duration_ms=(time.time() - retrieval_start) * 1000,
                    metadata={
                        "strategy": retrieval_result.strategy_used,
                        "docs_retrieved": retrieval_result.count,
                        "fallback_step": retrieval_result.fallback_step,
                        "top_score": retrieval_result.documents[0].get("score") if retrieval_result.documents else 0.0
                    }
                )
            
            if verbose:
                print(f"\n Retrieved {retrieval_result.count} documents")
                print(f"   Strategy: {retrieval_result.strategy_used}")
                print(f"   Fallback step: {retrieval_result.fallback_step}")
            
            # Step 4: Generate answer
            if verbose:
                print(f"\n Step 4: Answer Generation...")
            
            generation_start = time.time()
            answer_text, answer_confidence = self.answer_generator.generate(
                query,
                retrieval_result.documents,
                verbose=verbose
            )
            if logger:
                logger.log_component(
                    "answer_generation",
                    duration_ms=(time.time() - generation_start) * 1000,
                    metadata={
                        "model": self.answer_generator.model_id,
                        "answer_length": len(answer_text),
                        "confidence": answer_confidence
                    }
                )
            
            # Step 5: Validate answer
            validation_start = time.time()
            if verbose:
                print(f"\n✅ Step 5: Answer Validation...")
            
            validation = self.answer_generator.validate(answer_text, query)
            if logger:
                logger.log_component(
                    "answer_validation",
                    duration_ms=(time.time() - validation_start) * 1000,
                    metadata={
                        "is_valid": validation["is_valid"],
                        "word_count": validation["word_count"],
                        "issues": validation["issues"]
                    }
                )

            if verbose and not validation["is_valid"]:
                print(f"⚠️  Validation issues: {', '.join(validation['issues'])}")
            
            # Step 6: Package response
            elapsed_time = (time.time() - start_time) * 1000  # ms
            
            if verbose:
                self._print_summary(
                    retrieval_result,
                    answer_confidence,
                    validation,
                    elapsed_time
                )
            
            # Create response BEFORE logging success
            smart_answer = self._create_smart_answer(
                answer_text,
                retrieval_result,
                analysis,
                answer_confidence,
                validation,
                elapsed_time
)

            # Log success
            if logger:
                logger.log_success(
                    total_duration_ms=elapsed_time,
                    metrics={
                        "answer": answer_text[:200] + "...",  # Preview
                        "answer_length": len(answer_text),
                        "confidence": answer_confidence,
                        "source_count": len(retrieval_result.documents),
                        "strategy": retrieval_result.strategy_used,
                        "validation_passed": validation["is_valid"]
                    }
                )
            
            return smart_answer
        
        except Exception as e:
            if logger:
                logger.log_error(e, failed_component="ask_smart_pipeline")
            return self._handle_error(query, e, start_time, verbose)
        
    # --------------------------- Helper Methods --------------------------- #
    
    def _create_smart_answer(self,
                            answer_text: str,
                            retrieval_result,
                            analysis,
                            confidence: float,
                            validation: Dict,
                            elapsed_time: float) -> SmartAnswer:
        """
        Package all pipeline results into SmartAnswer object.
        
        Args:
            answer_text: Generated answer text
            retrieval_result: RetrievalResult from filter_gen
            analysis: QueryAnalysis from analyser
            confidence: Answer confidence score
            validation: Validation result dict
            elapsed_time: Total pipeline latency in ms
            
        Returns:
            SmartAnswer with answer, sources, metadata, and quality indicators
        """
        return SmartAnswer(
            answer=answer_text,
            sources=[
                {
                    "content": (doc.get("content") or "")[:300] + "...",  # Preview
                    "metadata": (doc.get("metadata") or {}),
                    "score": doc.get("score"),
                    "page_h1": (doc.get("metadata") or {}).get("page_h1", "Unknown"),
                    "root_heading": (doc.get("metadata") or {}).get("root_heading", "Unknown")
                }
                for doc in retrieval_result.documents[:3]  # Top 3 sources
            ],
            retrieval_metadata={
                "kb_id": self.kb_id,
                "strategy": retrieval_result.strategy_used,
                "filters_used": retrieval_result.filters_used,
                "fallback_step": retrieval_result.fallback_step,
                "docs_retrieved": retrieval_result.count,
                "analyzer_confidence": analysis.confidence_score,
                "query_type": analysis.intent_primary.get("type", "unknown"),
                "tools_mentioned": analysis.tools_mentioned,
                "notes": retrieval_result.notes,
                "latency_ms": elapsed_time
            },
            confidence=confidence,
            validation_issues=validation["issues"] if not validation["is_valid"] else []
        )
    
    def _handle_error(self,
                     query: str,
                     error: Exception,
                     start_time: float,
                     verbose: bool) -> SmartAnswer:
        """
        Handle pipeline errors gracefully and return error response.
        
        Args:
            query: Original user query
            error: Exception that occurred
            start_time: Pipeline start time
            verbose: Whether verbose logging is enabled
            
        Returns:
            SmartAnswer with error message and metadata
        """
        if verbose:
            print(f"\n PIPELINE FAILED: {error}")
            print(f"   Error type: {type(error).__name__}")
            traceback.print_exc()
        
        return SmartAnswer(
            answer="An error occurred while processing your question. Please try again or contact support if the issue persists.",
            sources=[],
            retrieval_metadata={
                "kb_id": self.kb_id,
                "strategy": "error",                    
                "filters_used": {},                     
                "fallback_step": -1,                    
                "docs_retrieved": 0,                    
                "analyzer_confidence": 0.0,             
                "query_type": "unknown",                
                "tools_mentioned": [],                  
                "notes": f"Pipeline error: {str(error)}", 
                "latency_ms": (time.time() - start_time) * 1000,
                "error": str(error),
                "error_type": type(error).__name__,
                "query": query
            },

            confidence=0.0,
            validation_issues=["Pipeline error"]
        )
    
    # ------------------------- Logging & Display ------------------------- #
    
    @staticmethod
    def _print_header(query: str):
        """Print pipeline start header."""
        print("\n" + "="*70)
        print(" SMART RAG PIPELINE START")
        print("="*70)
        print(f"Query: {query}")
        print()
    
    @staticmethod
    def _print_summary(retrieval_result, confidence: float, validation: Dict, elapsed_time: float):
        """Print pipeline completion summary."""
        print("\n" + "="*70)
        print("PIPELINE COMPLETE")
        print("="*70)
        print(f" Documents retrieved: {retrieval_result.count}")
        print(f" Strategy used: {retrieval_result.strategy_used}")
        print(f" Answer confidence: {confidence:.2f}")
        print(f"Validation: {'✅ Passed' if validation['is_valid'] else '⚠️  Issues detected'}")
        if not validation['is_valid']:
            print(f"   Issues: {', '.join(validation['issues'])}")
        print(f"  Pipeline latency: {elapsed_time:.0f}ms")
        print("="*70 + "\n")

""" 

## Summary of  Architecture:

| Class | Responsibility | Key Methods |
|-------|----------------|-------------|
| **KnowledgeBaseRetriever** | AWS KB operations | `retrieve()`, `_build_kb_filter()` |
| **AnswerGenerator** | LLM generation + validation | `generate()`, `validate()`, `_calculate_confidence()` |
| **AskSmart** | Pipeline orchestration | `ask()`, `_create_smart_answer()`, `_handle_error()` |
---

## Usage Example:

```python
# Initialize all components
query_analyser = QueryAnalyser(...)
retrieval_planner = RetrievalPlanner(...)
filter_generator = FilterGenerator(kb_id="ABC123", region="us-east-1")

# Initialize AskSmart
ask_smart = AskSmart(
    analyser=query_analyser,
    planner=retrieval_planner,
    filter_gen=filter_generator,
    kb_id="ABC123",
    kb_catalog=catalog
)

# Ask a question
result = ask_smart.ask("How do I install RStudio?", verbose=True)

# Use the result
print(result.answer)
print(f"Confidence: {result.confidence}")
print(f"Strategy: {result.retrieval_metadata['strategy']}")
"""

# ask_smart.py logs component events as they happen
# ask_smart.py calls logger.log_success() at the end
# lambda_handler.py just needs to call logger.finalize() in finally