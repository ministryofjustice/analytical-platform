
""" 
FilterGenerator: LLM-Powered Metadata Filtering and Retrieval Module

This module implements an intelligent metadata filtering system for AWS Bedrock Knowledge Bases,
combining LLM-based semantic reasoning with progressive fallback strategies to optimize
document retrieval quality and coverage.

Key Components:
--------------
1. **RetrievalResult**: Dataclass capturing retrieval outcomes with full observability
2. **FilterGenerator**: Main orchestrator handling filter generation, refinement, and execution

Core Workflow:
-------------
1. **Filter Refinement**: Uses LLM (Claude) to semantically expand and validate metadata filters
   - Analyzes user query intent and retrieval strategy
   - Suggests optimal page_h1 and root_heading filter values
   - Provides reasoning and confidence scores

2. **Initial Retrieval**: Executes first retrieval attempt with LLM-refined filters
   - Translates RetrievalPlan filters to AWS Bedrock filter format
   - Applies semantic filtering on metadata fields
   - Returns structured results with provenance

3. **Progressive Fallback**: Implements 4-step relaxation ladder when initial retrieval fails
   - Step 1: Relax secondary filters (e.g., remove root_heading constraints)
   - Step 2: Broaden primary filters (e.g., expand page_h1 to category list)
   - Step 3: Remove all filters, increase top_k
   - Step 4: Maximum retrieval with no constraints
   
4. **Quality Assessment**: Evaluates result sufficiency at each step
   - Checks minimum result count threshold
   - Optional: Semantic score validation (commented for future use)

┌─────────────────────────────────────────────────────────────┐
│                    FilterGenerator                          │
├─────────────────────────────────────────────────────────────┤
│  generate_and_retrieve()                                    │
│    │                                                         │
│    ├──► _refine_filters_with_llm()                         │
│    │      └─► Bedrock Runtime (Claude)                     │
│    │                                                         │
│    ├──► _build_bedrock_filter()                            │
│    │      └─► Translate to AWS filter format               │
│    │                                                         │
│    ├──► _execute_retrieval()                               │
│    │      └─► Bedrock Agent Runtime (KB)                   │
│    │                                                         │
│    └──► _assess_quality()                                  │
│           └─► Validate result sufficiency                   │
└─────────────────────────────────────────────────────────────┘

"""
from dataclasses import dataclass
from typing import Dict, Any, List, Optional
import boto3
import json
from botocore.exceptions import ClientError

from config import KB_ID, MODEL_ID, REGION,QUESTION_FILTER_GENERATOR_SYSTEM_PROMPT

@dataclass
class RetrievalResult:
    """
    Results from a single retrieval attempt.
    
    Attributes:
        documents (List[Dict]): Retrieved documents with metadata
        count (int): Number of documents retrieved
        strategy_used (str): Strategy that produced these results
        filters_used (Dict): Filters applied (for observability)
        fallback_step (int): Which fallback step (0 = initial, 1-4 = ladder)
        notes (str): Debugging/observability notes
    """
    documents: List[Dict[str, Any]]
    count: int
    strategy_used: str
    filters_used: Dict[str, Any]
    fallback_step: int
    notes: str


class FilterGenerator:
    """
    Generates and refines metadata filters for KB retrieval using LLM,
    then executes retrieval with fallback strategies.

    Handles:
    1. LLM-based filter refinement (semantic expansion)
    2. Filter translation (RetrievalPlan → Bedrock RetrievalFilter)
    3. Initial retrieval execution
    4. Fallback ladder execution (progressive relaxation)
    5. Result quality assessment
    
    Attributes:
        kb_id (str): Bedrock Knowledge Base ID
        model_arn (str): Bedrock model ARN for embeddings
        llm_model_id (str): Model ID for filter generation (Claude)
        region (str): AWS region
        bedrock_runtime_client: Boto3 Bedrock Runtime client (for LLM)
        bedrock_agent_client: Boto3 Bedrock Agent Runtime client (for KB)
    
        Example:
        >>> filter_gen = FilterGenerator(kb_id="ABC123", region="us-east-1")
        >>> result = filter_gen.generate_and_retrieve(
        ...     query="How do I install RStudio?",
        ...     plan=retrieval_plan,
        ...     kb_catalog=catalog,
        ...     verbose=True
        ... )
        >>> print(f"Retrieved {result.count} docs with strategy: {result.strategy_used}")
    """
    
    def __init__(self, 
                 kb_id: str, 
                 region: str = REGION,
                 llm_model_id: str = MODEL_ID):
        """
        Initialize FilterGenerator with Bedrock KB and LLM credentials.
        
        Args:
            kb_id (str): Knowledge Base ID (e.g., "KB123XYZ")
            model_arn (str): Embedding model ARN (e.g., "arn:aws:bedrock:...")
            llm_model_id (str): Claude model ID for filter generation
            region (str): AWS region (default: us-east-1)
        """
        self.kb_id = kb_id
        self.region = region
        self.llm_model_id = llm_model_id
        
        # Client for LLM calls (filter generation)
        self.bedrock_runtime_client = boto3.client(
            "bedrock-runtime",
            region_name=region
        )
        
        # Client for Knowledge Base retrieval
        self.bedrock_agent_client = boto3.client(
            "bedrock-agent-runtime",
            region_name=region
        )
    
    # ----------------------------- Public API ----------------------------- #
    
    def generate_and_retrieve(self, 
                             query: str, 
                             plan, 
                             kb_catalog: Dict,
                             verbose: bool = False) -> RetrievalResult:
        """
        Generate filters, execute retrieval, and handle fallback strategies.
        
        Args:
            query: User query
            plan: RetrievalPlan with strategy and fallback ladder
            kb_catalog: Available metadata values
            verbose: Enable detailed logging
            
        Returns:
            RetrievalResult with documents and metadata
        """
        if verbose:
            print("=" * 70)
            print(" FILTER GENERATION & RETRIEVAL")
            print("=" * 70)
        
        # Step 1: Refine filters with LLM
        refined = self._refine_filters_with_llm(query, plan, kb_catalog, verbose)
        refined_filters = refined.get("final_filters", plan.filters)
        
        if verbose:
            print(f"\n Refined filters: {json.dumps(refined_filters, indent=2)}")
            print(f" Reasoning: {refined.get('reasoning', 'N/A')}\n")
        
        # Step 2: Try initial retrieval with refined filters
        initial_filter = self._build_bedrock_filter(refined_filters)
        documents = self._execute_retrieval(query, plan.budget.top_k, initial_filter, verbose)
        
        if self._assess_quality(documents, plan.fallback.min_results):
            if verbose:
                print(f"✅ Initial strategy succeeded with {len(documents)} documents\n")
            return RetrievalResult(
                documents=documents,
                count=len(documents),
                strategy_used=plan.initial_strategy,
                filters_used=refined_filters,
                fallback_step=0,
                notes=f"Initial strategy succeeded with LLM-refined filters: {refined.get('reasoning', '')}"
            )
        
        if verbose:
            print(f"⚠️ Initial retrieval insufficient ({len(documents)} < {plan.fallback.min_results}), trying fallback...\n")
        
        # Step 3: Fallback ladder (steps 1-4)
        for step_idx, fallback_step in enumerate(plan.fallback.ladder[1:], start=1):
            if verbose:
                print(f" Fallback step {step_idx}: filters={fallback_step.filters}, top_k={fallback_step.top_k}")
            
            fallback_filter = self._build_bedrock_filter(fallback_step.filters)
            documents = self._execute_retrieval(query, fallback_step.top_k, fallback_filter, verbose)
            
            if self._assess_quality(documents, plan.fallback.min_results):
                if verbose:
                    print(f"✅ Fallback step {step_idx} succeeded with {len(documents)} documents\n")
                return RetrievalResult(
                    documents=documents,
                    count=len(documents),
                    strategy_used=f"{plan.initial_strategy}_fallback_{step_idx}",
                    filters_used=fallback_step.filters,
                    fallback_step=step_idx,
                    notes=f"Fallback step {step_idx} succeeded"
                )
        
        # Step 4: All fallbacks exhausted → return last attempt
        if verbose:
            print(f"⚠️ All fallback steps exhausted, returning final attempt ({len(documents)} documents)\n")
        
        return RetrievalResult(
            documents=documents,
            count=len(documents),
            strategy_used=f"{plan.initial_strategy}_fallback_final",
            filters_used=plan.fallback.ladder[-1].filters,
            fallback_step=len(plan.fallback.ladder),
            notes="All fallback steps exhausted, returning final attempt"
        )
    
    # ------------------------- Filter Transformation ------------------------- #
    
    @staticmethod
    def flatten_plan_filters(plan_filters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extract simple key-value pairs from complex filter structures.
        
        Converts:
            {"page_h1": {"equals": "RStudio"}} 
        To:
            {"page_h1": "RStudio"}
        
        Args:
            plan_filters: Complex filter dict from RetrievalPlan
            
        Returns:
            Flattened dict with direct key-value pairs
        """
        if not plan_filters:
            return {}

        out = {}
        for key in ("page_h1", "root_heading"):
            node = plan_filters.get(key)
            if isinstance(node, dict):
                if "equals" in node and isinstance(node["equals"], str):
                    out[key] = node["equals"]
                elif "in" in node and isinstance(node["in"], list) and node["in"]:
                    out[key] = node["in"]
        return out
    
    def _build_bedrock_filter(self, filters: Dict[str, Any]) -> Optional[Dict]:
        """
        Convert simple filters to AWS Bedrock filter structure.
        
        Converts:
            {"page_h1": "RStudio", "root_heading": ["Install", "Setup"]}
        To:
            {"andAll": [
                {"equals": {"key": "page_h1", "value": "RStudio"}},
                {"in": {"key": "root_heading", "value": ["Install", "Setup"]}}
            ]}
        
        Args:
            filters: Simple key-value filter dict
            
        Returns:
            AWS Bedrock-compatible filter structure or None
        """
        if not filters:
            return None
        
        conditions = []
        
        # Handle page_h1
        page_h1 = filters.get("page_h1")
        if page_h1:
            if isinstance(page_h1, dict):
                # Already structured (from plan)
                if "equals" in page_h1 and page_h1["equals"]:
                    conditions.append({
                        "equals": {
                            "key": "page_h1",
                            "value": page_h1["equals"]
                        }
                    })
                elif "in" in page_h1 and page_h1["in"]:
                    conditions.append({
                        "in": {
                            "key": "page_h1",
                            "value": page_h1["in"]
                        }
                    })
            elif isinstance(page_h1, str):
                # Simple string value
                conditions.append({
                    "equals": {
                        "key": "page_h1",
                        "value": page_h1
                    }
                })
            elif isinstance(page_h1, list):
                # List of values
                conditions.append({
                    "in": {
                        "key": "page_h1",
                        "value": page_h1
                    }
                })
        
        # Handle root_heading
        root_heading = filters.get("root_heading")
        if root_heading:
            if isinstance(root_heading, dict):
                # Already structured (from plan)
                if "equals" in root_heading and root_heading["equals"]:
                    conditions.append({
                        "equals": {
                            "key": "root_heading",
                            "value": root_heading["equals"]
                        }
                    })
                elif "in" in root_heading and root_heading["in"]:
                    conditions.append({
                        "in": {
                            "key": "root_heading",
                            "value": root_heading["in"]
                        }
                    })
            elif isinstance(root_heading, str):
                # Simple string value
                conditions.append({
                    "equals": {
                        "key": "root_heading",
                        "value": root_heading
                    }
                })
            elif isinstance(root_heading, list):
                # List of values
                conditions.append({
                    "in": {
                        "key": "root_heading",
                        "value": root_heading
                    }
                })
        
        if not conditions:
            return None
        
        # Bedrock requires "andAll" wrapper for multiple conditions
        if len(conditions) == 1:
            return conditions[0]
        else:
            return {"andAll": conditions}
    
    # --------------------------- LLM Refinement --------------------------- #
    
    def _refine_filters_with_llm(self, 
                                  query: str, 
                                  plan, 
                                  kb_catalog: Dict,
                                  verbose: bool = False) -> Dict:
        """
        Use LLM to refine and validate metadata filters.
        
        Args:
            query: User query
            plan: RetrievalPlan with initial filters
            kb_catalog: Available metadata values
            verbose: Enable logging
            
        Returns:
            Dict with refined filters, reasoning, and confidence
        """
        # Build user message with context
        user_message = f"""Query: "{query}"

Strategy: {plan.initial_strategy}
Confidence Score: {plan.notes}

Current filters from RetrievalPlan:
{json.dumps(plan.filters, indent=2)}

Available page_h1 values:
{json.dumps(kb_catalog.get('page_h1_list', []), indent=2)}

Available root_heading values:
{json.dumps(kb_catalog.get('all_headings', []), indent=2)}

Based on the {plan.initial_strategy} strategy, suggest the optimal metadata filters."""

        try:
            request_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1500,
                "temperature": 0.1,
                "system": QUESTION_FILTER_GENERATOR_SYSTEM_PROMPT,
                "messages": [
                    {
                        "role": "user",
                        "content": [{"type": "text", "text": user_message}]
                    }
                ]
            }
            
            if verbose:
                print(f" Calling LLM for filter refinement...")
            
            response = self.bedrock_runtime_client.invoke_model(
                modelId=self.llm_model_id,
                body=json.dumps(request_body)
            )
            
            response_body = json.loads(response["body"].read())
            blocks = response_body.get("content", [])
            
            if not blocks:
                if verbose:
                    print("⚠️ Empty LLM response, using original filters")
                return {"final_filters": plan.filters, "reasoning": "LLM returned empty", "alternatives": {}}
            
            # Extract text from response
            text_parts = []
            for b in blocks:
                if b.get("type") == "text" and "text" in b:
                    text_parts.append(b["text"])
            analysis_text = "\n".join(text_parts).strip()
            
            # Strip code fences if present
            analysis_text = self._strip_code_fences(analysis_text)
            
            # Parse JSON
            try:
                refined_filters = json.loads(analysis_text)
                
                if verbose:
                    print(f"✅ LLM refined filters:")
                    print(f"   final_filters: {refined_filters.get('final_filters')}")
                    print(f"   reasoning: {refined_filters.get('reasoning')}")
                    print(f"   confidence: {refined_filters.get('confidence_in_filters')}")
                
                return refined_filters
            
            except json.JSONDecodeError as e:
                if verbose:
                    print(f"⚠️ JSON parse error: {e}")
                    print(f"Raw LLM output: {analysis_text[:500]}")
                # Fallback to original filters
                return {"final_filters": plan.filters, "reasoning": "JSON parse failed", "alternatives": {}}
        
        except ClientError as e:
            if verbose:
                print(f"⚠️ LLM call failed: {e}")
            # Fallback to original filters
            return {"final_filters": plan.filters, "reasoning": "LLM call failed", "alternatives": {}}
    
    @staticmethod
    def _strip_code_fences(s: str) -> str:
        """Remove markdown code fences from LLM output."""
        s = s.strip()
        if s.startswith("```json"):
            s = s[len("```json"):].strip()
        if s.startswith("```"):
            s = s[len("```"):].strip()
        if s.endswith("```"):
            s = s[:-3].strip()
        return s
    
    # ---------------------------- KB Retrieval ---------------------------- #
    
    def _execute_retrieval(self, 
                          query: str, 
                          top_k: int, 
                          bedrock_filter: Optional[Dict],
                          verbose: bool = False) -> List[Dict]:
        """
        Execute retrieval against AWS Bedrock Knowledge Base.
        
        Args:
            query: Search query
            top_k: Number of results to retrieve
            bedrock_filter: AWS Bedrock filter structure
            verbose: Enable logging
            
        Returns:
            List of retrieved documents
        """
        try:
            params = {
                "knowledgeBaseId": self.kb_id,
                "retrievalQuery": {"text": query},
                "retrievalConfiguration": {
                    "vectorSearchConfiguration": {
                        "numberOfResults": top_k
                    }
                }
            }
            
            # Add filter if provided
            if bedrock_filter:
                params["retrievalConfiguration"]["vectorSearchConfiguration"]["filter"] = bedrock_filter
            
            if verbose:
                print(f" Executing retrieval: top_k={top_k}, filter={'Yes' if bedrock_filter else 'None'}")
            
            response = self.bedrock_agent_client.retrieve(**params)
            
            # Extract documents
            documents = []
            for result in response.get("retrievalResults", []):
                documents.append({
                    "content": result.get("content", {}).get("text", ""),
                    "score": result.get("score", 0.0),
                    "metadata": result.get("metadata", {}),
                    "location": result.get("location", {})
                })
            
            if verbose:
                print(f" Retrieved {len(documents)} documents")
            
            return documents
        
        except ClientError as e:
            if verbose:
                print(f" Bedrock retrieval error: {e}")
            raise
    
    # ------------------------- Quality Assessment ------------------------- #
    
    def _assess_quality(self, documents: List[Dict], min_results: int) -> bool:
        """
        Assess whether retrieved documents meet quality thresholds.
        
        Args:
            documents: Retrieved documents
            min_results: Minimum number of results required
            
        Returns:
            True if quality threshold met
        """
        # Simple count check
        if len(documents) < min_results:
            return False
        
        # Optional: Check semantic scores
        # Uncomment when ready to enable score-based quality assessment
        # if documents:
        #     avg_score = sum(d["score"] for d in documents) / len(documents)
        #     if avg_score < 0.65:
        #         return False
        
        return True