"""
Utility functions for AWS Bedrock Knowledge Base interactions

AWS Bedrock Knowledge Base Query Utilities

This module provides a high-level interface for querying AWS Bedrock Knowledge Bases
with support for metadata filtering, conversational sessions, and citation extraction.

CORE FUNCTIONS:
- ask()  : User-friendly interface with formatted markdown output (for notebooks)
- chat() : Programmatic interface returning raw text and citations (for automation)

--- 

METADATA FILTERING:
Use MetadataFilters helper class or custom dictionaries to narrow retrieval scope:
- Filter by page, section, heading level
- Combine filters with AND/OR logic
- Use operators: equals, contains, in, notEquals, etc.

---

RETRIEVAL STRATEGY:
Uses Bedrock's retrieve_and_generate API with:
1. Vector/hybrid search to find relevant chunks
2. Metadata filtering to scope results
3. LLM generation with custom prompt template
4. Citation extraction (with fallback mechanisms)

---

CITATION EXTRACTION (Multi-layer fallback):
1. Primary: Extract from response citations (when $output_format_instructions$ works)
2. Fallback 1: Use retrievalResults from response
3. Fallback 2: Separate retrieve() call for diagnostics

---

UTILITIES:
- display_citations_table() : View citations as pandas DataFrame
- export_qa_to_markdown()   : Save Q&A sessions to markdown files

---
CONFIGURATION:
Create a config.py file in the same directory with:

```python
# AWS Configuration
KB_ID = "your-knowledge-base-id"  # Your Bedrock Knowledge Base ID
MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"  # Model to use
REGION = "us-east-1"  # AWS region

# System Prompt
SYSTEM_PROMPT = '''You are a helpful assistant for the Analytical Platform documentation.
Provide clear, accurate answers based on the retrieved context.
If information is not in the context, say so clearly.'''

# Retrieval Configuration
DEFAULT_NUMBER_OF_RESULTS = 5  # Documents to retrieve per query
DEFAULT_SEARCH_TYPE = "HYBRID"  # HYBRID, SEMANTIC, or KEYWORD

---

QUICK START EXAMPLES:

Basic usage:
    ask("How do I use RStudio?")

Debug mode (see retrieval details): ask("How do I use RStudio?", verbose=True) # Shows: documents retrieved, relevance scores, extraction method

With metadata filtering:
    ask("What are GitHub rules?", 
        metadata_filters=MetadataFilters.by_page("aup.html"))

Programmatic usage (for scripts/automation):
    answer, citations = chat("How do I install packages?")
    process_answer(answer)

Save Q&A to file: answer, citations = chat("How do I use RStudio?") export_qa_to_markdown("How do I use RStudio?", answer, citations)

Multiple filters combined:
    ask("How do I access data?",
        metadata_filters={
            "root_heading": {"in": ["Athena", "S3"]},
            "page_url": {"stringContains": "data-access"}
        })

Session continuity (multi-turn conversation):
    session = "user-123-session"
    ask("What is RStudio?", session_id=session)
    ask("How do I install packages there?", session_id=session)  # Maintains context

ask("How do I install packages there?", session_id=session) # "there" correctly refers to RStudio from previous question

---
ERROR HANDLING: Functions handle errors gracefully:

chat() returns: ("Error: ...", []) on failure
ask() displays formatted error message
Use verbose=True to see detailed error diagnostics
Common issues:

"No documents retrieved" → Try relaxing metadata filters
"AWS Error" → Check KB_ID, MODEL_ID, and AWS credentials
"Empty citations" → May indicate prompt template issue (fallback used automatically)
LIMITATIONS:

Embedded links feature: Currently disabled in source display (code commented out)
Session continuity: Requires same session_id across calls (not persisted)
Metadata filters: Must match exact field names in your Knowledge Base schema
"""

import json
import boto3
from typing import Dict, List, Optional, Tuple
from botocore.exceptions import BotoCoreError, ClientError
from IPython.display import display, Markdown
import pandas as pd
from datetime import datetime

from config import KB_ID, MODEL_ID, REGION, SYSTEM_PROMPT, DEFAULT_NUMBER_OF_RESULTS, DEFAULT_SEARCH_TYPE

def bedrock():
    """Bedrock Agent Runtime client for Knowledge Base operations"""
    return boto3.client("bedrock-agent-runtime", region_name = REGION)

def bedrock_runtime():
    """Bedrock Runtime client for direct model inference"""
    return boto3.client("bedrock-runtime", region_name = REGION)

def _model_arn(model_id: str, region: str = REGION) -> str:
    """
    Compose a Bedrock foundation-model ARN(resource name) for the given model ID and region.
    """
    if ":" not in model_id:
        raise ValueError(
            f"model_id looks incomplete: {model_id!r}. "
            "Use an exact Bedrock model ID with version, e.g. "
            "'anthropic.claude-3-sonnet-20240229-v1:0'"
        )
    return f"arn:aws:bedrock:{region}::foundation-model/{model_id}"

# ================================================================================
# METADATA FILTER HELPERS
# ================================================================================

def _build_metadata_filter(filters: Dict) -> Dict:
    """
    Build metadata filter structure for Bedrock Knowledge Base.
    
    Filters are wrapped in logical operators (andAll, orAll) when combining 
    multiple conditions. Single conditions are returned unwrapped.
    
    Supports operators:
    - equals: Exact match
    - notEquals: Not equal
    - stringContains: Substring match
    - greaterThan, greaterThanOrEquals: Numeric comparison
    - lessThan, lessThanOrEquals: Numeric comparison
    - in: Match any value in list
    - notIn: Don't match any value in list
    
    Args:
        filters: Dictionary of field->operator->value mappings
        
    Returns:
        Formatted filter structure for Bedrock API
        
    Examples:
        # Single filter
        {"page_h1": {"equals": "User Guide"}}
        
        # Multiple filters (AND logic - default)
        {
            "root_heading": {"equals": "RStudio"},
            "page_url": {"stringContains": "tools"}
        }
        
        # Multiple filters (OR logic)
        {
            "_logic": "OR",
            "root_heading": {"equals": "RStudio"},
            "page_h1": {"equals": "JupyterLab"}
        }
        
        # Using 'in' operator
        {
            "root_heading": {"in": ["RStudio", "JupyterLab", "Athena"]}
        }
    """
    if not filters:
        return {}
    
    # Valid operators
    VALID_OPERATORS = {
        'equals', 'notEquals', 'stringContains',
        'greaterThan', 'greaterThanOrEquals',
        'lessThan', 'lessThanOrEquals',
        'in', 'notIn'
    }
    
    # Extract logic operator (defaults to AND)
    # Make a copy to avoid modifying the original dict
    filters_copy = filters.copy()
    LIST_OPERATORS = {'in', 'notIn'}
    NUMERIC_OPERATORS = {'greaterThan', 'greaterThanOrEquals', 'lessThan', 'lessThanOrEquals'}
    
    # Extract logic operator (defaults to AND)
    logic = filters_copy.pop('_logic', 'AND').upper()
    logic_key = 'andAll' if logic == 'AND' else 'orAll'
    
    # Build list of filter conditions
    filter_conditions = []
    for key, condition in filters_copy.items():
        if not isinstance(condition, dict):
            raise ValueError(f"Filter condition for '{key}' must be a dict, got {type(condition)}")
        
        for operator, value in condition.items():
            # Validate operator
            if operator not in VALID_OPERATORS:
                raise ValueError(
                    f"Invalid operator '{operator}' for field '{key}'. "
                    f"Valid operators: {', '.join(sorted(VALID_OPERATORS))}"
                )
            
            # Validate value types
            if value is None:
                raise ValueError(f"Filter value for '{key}.{operator}' cannot be None")
            
            if operator in LIST_OPERATORS and not isinstance(value, list):
                raise ValueError(f"Operator '{operator}' requires a list value, got {type(value)}")
            
            if operator in NUMERIC_OPERATORS and not isinstance(value, (int, float)):
                raise ValueError(f"Operator '{operator}' requires a numeric value, got {type(value)}")
            
            filter_conditions.append({
                operator: {
                    "key": key,
                    "value": value
                }
            })
    
    # Handle different cases
    if len(filter_conditions) == 0:
        return {}
    elif len(filter_conditions) == 1:
        # Return single filter unwrapped
        return filter_conditions[0]
    else:
        # Multiple filters - wrap with logic operator
        return {logic_key: filter_conditions}
    
class MetadataFilters:
    """
    Helper class for building common metadata filters.
    
    Examples:
        # Filter by page
        ask("Question?", metadata_filters=MetadataFilters.by_page("aup.html"))
        
        # Filter by heading
        ask("Question?", metadata_filters=MetadataFilters.by_heading("RStudio"))
        
        # Filter by page AND heading
        ask("Question?", metadata_filters=MetadataFilters.by_page_and_heading("tools", "JupyterLab"))
        
        # Filter by multiple headings
        ask("Question?", metadata_filters=MetadataFilters.by_any_heading(["Athena", "SQL"]))
    """
    
    @staticmethod
    def by_page(page_url_substring: str) -> Dict:
        """Filter results to a specific page (by URL substring)."""
        return {
            "page_url": {"stringContains": page_url_substring}
        }
    
    @staticmethod
    def by_heading(heading: str) -> Dict:
        """Filter results to a specific documentation section."""
        return {
            "root_heading": {"equals": heading}
        }
    
    @staticmethod
    def by_page_title(title: str) -> Dict:
        """Filter results to pages with specific title (substring match)."""
        return {
            "page_h1": {"stringContains": title}
        }
    
    @staticmethod
    def by_exact_page_title(title: str) -> Dict:
        """Filter results to pages with exact title match."""
        return {
            "page_h1": {"equals": title}
        }
    
    @staticmethod
    def by_page_and_heading(page_url_substring: str, heading: str) -> Dict:
        """Filter by both page and heading section."""
        return {
            "page_url": {"stringContains": page_url_substring},
            "root_heading": {"equals": heading}
        }
    
    @staticmethod
    def by_any_heading(headings: List[str]) -> Dict:
        """Filter to any of the specified headings."""
        return {
            "root_heading": {"in": headings}
        }
    
    @staticmethod
    def by_heading_level(level: int) -> Dict:
        """Filter by heading level (1=h1, 2=h2, etc.)."""
        return {
            "level": {"equals": level}
        }
    
    @staticmethod
    def exclude_page(page_url_substring: str) -> Dict:
        """Exclude a specific page from results."""
        return {
            "page_url": {"notEquals": page_url_substring}
        }
    
    @staticmethod
    def custom(filters: Dict) -> Dict:
        """
        Build a custom filter.
        
        Example:
            MetadataFilters.custom({
                "page_url": {"stringContains": "data-access"},
                "level": {"lessThanOrEquals": 2}
            })
        """
        return filters
    
# ================================================================================
# CORE FUNCTIONS
# ================================================================================
# 1. Retrieve and Generate WITH METADATA Filter
# 2. CHAT FUNCTIONS (Programmatic Interface)
# 3. ASK FUNCTION (User-Friendly Interface)

def retrieve_and_generate_with_sources(
    query: str,
    metadata_filters: Optional[Dict] = None,
    model_id: str = MODEL_ID,
    system_prompt: str = SYSTEM_PROMPT,
    region: str = REGION,
    session_id: Optional[str] = None,
    number_of_results: int = DEFAULT_NUMBER_OF_RESULTS,
    search_type: str = DEFAULT_SEARCH_TYPE,
    verbose: bool = False
):
    """
    Retrieve and generate with optional metadata filtering and REAL relevance scores.
    
    This function performs a two-step process:
    1. Calls retrieve() API to get documents with real relevance scores
    2. Calls retrieve_and_generate() to get AI-generated answer
    3. Merges the real scores into the citations
    
    Args:
        query: User question
        metadata_filters: Optional dictionary of metadata filters to apply
        model_id: Bedrock model ID
        system_prompt: Custom system prompt
        region: AWS region
        session_id: Optional session ID for conversation continuity
        number_of_results: Number of documents to retrieve
        search_type: HYBRID, SEMANTIC, or KEYWORD
        verbose: If True, print processing information
    
    Returns:
        Response with answer and retrieved documents WITH REAL SCORES
    """
    try:
        if verbose:
            print(f" Retrieving and generating for: '{query}'")
            if metadata_filters:
                print(f" Applying metadata filters: {json.dumps(metadata_filters, indent=2)}")
            print(f" Search type: {search_type}")
        
        # ═══════════════════════════════════════════════════════════════
        # BUILD RETRIEVAL CONFIGURATION
        # ═══════════════════════════════════════════════════════════════
        retrieval_config = {
            'vectorSearchConfiguration': {
                'numberOfResults': number_of_results
            }
        }
        
        # Add metadata filter if provided
        if metadata_filters:
            filter_structure = _build_metadata_filter(metadata_filters)
            if filter_structure:
                retrieval_config['vectorSearchConfiguration']['filter'] = filter_structure
                if verbose:
                    print(f"🔧 Built filter structure: {json.dumps(filter_structure, indent=2)}")
        
        # ═══════════════════════════════════════════════════════════════
        # STEP 1: Get retrieval results WITH SCORES using Retrieve API
        # ═══════════════════════════════════════════════════════════════
        if verbose:
            print(f"\n Step 1: Retrieving documents with scores...")
        
        retrieve_response = bedrock().retrieve(
            knowledgeBaseId=KB_ID,
            retrievalConfiguration=retrieval_config,
            retrievalQuery={'text': query}
        )
        
        # Build score mapping by S3 URI and chunk ID
        score_map = {}
        scored_docs = retrieve_response.get('retrievalResults', [])
        
        for result in scored_docs:
            # Map by S3 URI
            s3_uri = result.get('location', {}).get('s3Location', {}).get('uri', '')
            score = result.get('score', 0.0)
            
            if s3_uri:
                score_map[s3_uri] = score
            
            # Also map by chunk ID if available
            chunk_id = result.get('metadata', {}).get('x-amz-bedrock-kb-chunk-id', '')
            if chunk_id:
                score_map[chunk_id] = score
        
        if verbose:
            print(f"✓ Retrieved {len(scored_docs)} documents with scores")
            for i, result in enumerate(scored_docs[:3], 1):
                score = result.get('score', 0)
                metadata = result.get('metadata', {})
                page = metadata.get('page_h1', 'Unknown')
                section = metadata.get('root_heading', 'N/A')
                print(f"   {i}. [{score*100:.1f}%] {page} → {section}")
            if len(scored_docs) > 3:
                print(f"   ... and {len(scored_docs) - 3} more")
        
        # ═══════════════════════════════════════════════════════════════
        # STEP 2: Generate answer using RetrieveAndGenerate
        # ═══════════════════════════════════════════════════════════════
        if verbose:
            print(f"\n Step 2: Generating answer...")
        
        # Build model ARN
        model_arn = _model_arn(model_id, region=region)

        # Build prompt template
        prompt_template = (
            f"{system_prompt}\n\n"
            "Retrieved Context:\n$search_results$\n\n"
            "User Question: $query$\n\n"
            "Instructions:\n"
            "- Analyze the Retrieved Context carefully\n"
            "- Check if the context DIRECTLY answers the specific question asked\n"
            "- Pay attention to specific tools/processes mentioned in the question\n"
            "- If the context covers a DIFFERENT tool/process than asked about, state that the specific tool is not documented\n"
            "- DO NOT substitute information from Tool B when asked about Tool A\n"
            "- If the specific process is not documented, use the refusal message - do NOT provide alternatives\n"
            "- Only cite sections that DIRECTLY answer the user's specific question\n\n"
            "Answer:\n"
            "$output_format_instructions$"
        )

        # Configure retrieve and generate
        retrieve_and_generate_cfg = {
            "type": "KNOWLEDGE_BASE",
            "knowledgeBaseConfiguration": {
                "knowledgeBaseId": KB_ID,
                "modelArn": model_arn,
                "retrievalConfiguration": retrieval_config,
                "generationConfiguration": {
                    "inferenceConfig": {
                        "textInferenceConfig": {
                            "temperature": 0,
                            "maxTokens": 1500
                        }
                    },
                    "promptTemplate": {
                        "textPromptTemplate": prompt_template
                    }
                }
            }
        }
       
        # Add session ID if provided
        kwargs = {}
        if session_id:
            kwargs["sessionId"] = session_id

        # API call: retrieve AND generate
        generation_response = bedrock().retrieve_and_generate(
            input={"text": query},
            retrieveAndGenerateConfiguration=retrieve_and_generate_cfg,
            **kwargs
        )
        
        # ═══════════════════════════════════════════════════════════════
        # STEP 3: Merge real scores into citations
        # ═══════════════════════════════════════════════════════════════
        if verbose:
            print(f"\n🔗 Step 3: Merging scores into citations...")
        
        retrieved_docs = []
        extraction_method = None
        matched_scores = 0
        
        # Extract from citations (PRIMARY)
        citations = generation_response.get('citations', [])
        if citations:
            for citation in citations:
                retrieved_refs = citation.get('retrievedReferences', [])
                
                for ref in retrieved_refs:
                    # Try to match score by S3 URI
                    s3_uri = ref.get('location', {}).get('s3Location', {}).get('uri', '')
                    
                    # Try to match score by chunk ID
                    chunk_id = ref.get('metadata', {}).get('x-amz-bedrock-kb-chunk-id', '')
                    
                    # Look up the real score
                    matched_score = None
                    
                    if s3_uri in score_map:
                        matched_score = score_map[s3_uri]
                        matched_scores += 1
                    elif chunk_id in score_map:
                        matched_score = score_map[chunk_id]
                        matched_scores += 1
                    
                    # Inject the real score!
                    if matched_score is not None:
                        ref['score'] = matched_score
                    else:
                        # Keep original (probably 0) and warn
                        ref['score'] = ref.get('score', 0.0)
                        if verbose:
                            print(f"   ⚠️  Could not match score for chunk: {chunk_id[:20] if chunk_id else 'unknown'}...")
                    
                    retrieved_docs.append(ref)
                
            extraction_method = "citations_with_scores"
        
        # FALLBACK: Use scored docs directly if no citations
        if not retrieved_docs:
            retrieved_docs = scored_docs
            extraction_method = "scored_docs_direct"
        
        if verbose:
            print(f"✓ Matched scores for {matched_scores}/{len(retrieved_docs)} documents")
            print(f"✓ Extraction method: {extraction_method}")
        
        # Add metadata to response
        generation_response['_retrieved_docs'] = retrieved_docs
        generation_response['_metadata_filters'] = metadata_filters
        generation_response['_search_type'] = search_type
        generation_response['_extraction_method'] = extraction_method
        generation_response['_score_match_rate'] = f"{matched_scores}/{len(retrieved_docs)}"
        
        # ═══════════════════════════════════════════════════════════════
        # VERBOSE OUTPUT - Statistics and Diagnostics
        # ═══════════════════════════════════════════════════════════════
        if verbose:
            print(f"\n Final Results:")
            print(f"   Retrieved: {len(retrieved_docs)} documents")
            print(f"   Score coverage: {matched_scores}/{len(retrieved_docs)}")
            
            if retrieved_docs:
                print("\n Top documents with scores:")
                
                # Sort by score
                sorted_docs = sorted(
                    retrieved_docs, 
                    key=lambda x: x.get('score', 0), 
                    reverse=True
                )
                
                for i, doc in enumerate(sorted_docs[:5], 1):
                    metadata = doc.get('metadata', {})
                    page_title = metadata.get('page_h1', 'Unknown')
                    section = metadata.get('root_heading', 'N/A')
                    score = doc.get('score', 0)
                    print(f"   {i}. [{score*100:.1f}%] {page_title} → {section}")
                
                if len(sorted_docs) > 5:
                    print(f"   ... and {len(sorted_docs) - 5} more")
                
                # Show score distribution
                scores = [doc.get('score', 0) for doc in retrieved_docs]
                print(f"\n Score distribution:")
                print(f"   Max:  {max(scores)*100:.1f}%")
                print(f"   Mean: {sum(scores)/len(scores)*100:.1f}%")
                print(f"   Min:  {min(scores)*100:.1f}%")
                
                # Group by section
                from collections import defaultdict
                by_section = defaultdict(list)
                
                for doc in retrieved_docs:
                    metadata = doc.get('metadata', {})
                    section = metadata.get('root_heading', 'Unknown')
                    by_section[section].append(doc)
                
                print(f"\n Sections covered: {len(by_section)}")
                
                # Diversity warning
                if len(by_section) > 3 and not metadata_filters:
                    print(f"    High diversity: {len(by_section)} different sections")
                    print(f"   Consider using metadata filters for more focused results")
            else:
                print("    WARNING: No documents retrieved!")
                if metadata_filters:
                    print("   Possible issues:")
                    print("   - Metadata filters too restrictive")
                    print("   - Try relaxing filter conditions")
                else:
                    print("   Possible issues:")
                    print("   - Knowledge base might be empty")
                    print("   - Query doesn't match any indexed content")
            
            print("\n Successfully generated response with real scores!\n")
        
        return generation_response

    except (BotoCoreError, ClientError) as e:
        print(f" AWS Error: {str(e)}")
        print(f"   Error type: {type(e).__name__}")
        if hasattr(e, 'response'):
            error_details = e.response.get('Error', {})
            print(f"   Error Code: {error_details.get('Code', 'Unknown')}")
            print(f"   Error Message: {error_details.get('Message', 'Unknown')}")
        import traceback
        traceback.print_exc()
        return None
        
    except Exception as e:
        print(f" Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return None
   
# ================================================================================
# CHAT FUNCTIONS (Programmatic Interface)
# ================================================================================

def chat(
    question: str,
    metadata_filters: Optional[Dict] = None,
    model_id: str = MODEL_ID,
    number_of_results: int = DEFAULT_NUMBER_OF_RESULTS,
    session_id: Optional[str] = None,
    verbose: bool = False
) -> Tuple[str, List[Dict]]:
    """
    Chat with the Knowledge Base with optional metadata filtering - Programmatic interface.
    Returns answer text and citations for further processing.
    
    Args:
        question: User question
        metadata_filters: Dictionary of metadata filters to apply
        model_id: Bedrock model ID
        session_id: Optional session ID for conversation continuity
        number_of_results: Number of documents to retrieve
        verbose: If True, print processing information
    
    Returns:
        Tuple of (answer_text, citations_list)
    
    Examples:
        # Basic usage
        answer, citations = chat("How do I delete a table in Athena?")
        
        # With metadata filtering - search only in RStudio docs
        answer, citations = chat(
            "How do I install packages?",
            metadata_filters={"root_heading": {"equals": "RStudio"}}
        )
        
        # Search in specific page
        answer, citations = chat(
            "What are the GitHub rules?",
            metadata_filters={"page_url": {"stringContains": "aup.html"}}
        )
    """
    try:
        result = retrieve_and_generate_with_sources(
            query=question,
            metadata_filters=metadata_filters,
            model_id=model_id,
            session_id=session_id,
            number_of_results=number_of_results,
            verbose=verbose
        )
        
        if not result:
            return "Error: No response from Knowledge Base", []

        # Extract answer
        answer = result.get("output", {}).get("text", "No answer generated")
        
        # Get retrieved docs and format as citations
        retrieved_docs = result.get('_retrieved_docs', [])
        
        citations = []
        for doc in retrieved_docs:
            citation = {
                "retrievedReferences": [{
                    "content": doc.get("content", {}),
                    "location": doc.get("location", {}),
                    "metadata": doc.get("metadata", {}),
                    "score": doc.get("score", 0)
                }]
            }
            citations.append(citation)
        
        return answer, citations
        
    except Exception as e:
        print(f"Error in chat(): {str(e)}")
        import traceback
        traceback.print_exc()
        return f"Error: {str(e)}", []

# ================================================================================
# ASK FUNCTION (User-Friendly Interface)
# ================================================================================

def ask(
    question: str,
    metadata_filters: Optional[Dict] = None,
    model_id: str = MODEL_ID,
    number_of_results: int = 5,
    session_id: Optional[str] = None,
    show_metadata: bool = False,
    show_full_citations: bool = False
):
    """
    Ask a question to the Knowledge Base with optional metadata filtering - User-friendly interface.
    
    Args:
        question: User question
        metadata_filters: Dictionary of metadata filters to apply (see examples below)
        model_id: Bedrock model ID
        number_of_results: Number of documents to retrieve
        session_id: Optional session ID for conversation continuity
        show_metadata: If True, display technical metadata (for debugging)
        show_full_citations: If True, show complete citation details including content
    
    Returns:
        Tuple of (answer_text, citations_list)
    
    Examples:
        # Basic usage (no filtering)
        ask("How do I set up RStudio on the Analytical Platform?")
        
        # Filter by page section
        ask(
            "How do I install packages?",
            metadata_filters={"root_heading": {"equals": "RStudio"}}
        )
        
        # Filter by page URL
        ask(
            "What are the GitHub rules?",
            metadata_filters={"page_url": {"stringContains": "aup.html"}}
        )
        
        # Combine multiple filters
        ask(
            "What are the rules?",
            metadata_filters={
                "page_url": {"stringContains": "aup.html"},
                "root_heading": {"equals": "GitHub"}
            }
        )
        
        # Search across multiple sections
        ask(
            "How do I access data?",
            metadata_filters={"root_heading": {"in": ["Athena", "S3", "Data Access"]}}
        )
        
        # Debug mode with full details
        ask("How do I set up RStudio?", show_metadata=True, show_full_citations=True)
    """
    
    answer, citations = chat(
        question=question,
        metadata_filters=metadata_filters,
        model_id=model_id,
        session_id=session_id,
        number_of_results=number_of_results,
        verbose=show_metadata
    )
   
    # =================================================================
    # 1. QUESTION (with filter info if applicable)
    # =================================================================
    display(Markdown("---"))
    display(Markdown(f"### **Question**\n\n{question}"))
    
    if metadata_filters:
        display(Markdown("\n** Metadata Filters Applied:**"))
        display(Markdown("```json\n" + json.dumps(metadata_filters, indent=2) + "\n```"))
    
    # =================================================================
    # 2. ANSWER
    # =================================================================
    display(Markdown("\n---"))
    display(Markdown("### **Answer**\n"))
    display(Markdown(answer))
    
    # =================================================================
    # 3. SOURCES
    # =================================================================
    display(Markdown("\n---"))
    display(Markdown("###  **Sources**\n"))
    
    if citations:
        sources = []
        for citation in citations:
            retrieved_refs = citation.get('retrievedReferences', [])
            
            for ref in retrieved_refs:
                metadata = ref.get("metadata", {})
                content = ref.get('content', {}).get("text", "")
                score = ref.get('score', 0)
                
                page_title = metadata.get('page_h1', 'Unknown Document')
                page_url = metadata.get('page_url', '')
                section = metadata.get('root_heading', '')
                
                # Extract embedded links from metadata
                embedded_links = []
                link_idx = 1
                while f'link_{link_idx}_text' in metadata:
                    link_text = metadata.get(f'link_{link_idx}_text')
                    link_url = metadata.get(f'link_{link_idx}_url')
                    if link_text and link_url:
                        embedded_links.append({'text': link_text, 'url': link_url})
                    link_idx += 1
                
                # Format: "Page Title: Section" or just "Page Title"
                if section and section != page_title:
                    source_text = f"{page_title}: {section}"
                else:
                    source_text = page_title
                
                # Create markdown link
                if page_url:
                    source_link = f"[{source_text}]({page_url})"
                else:
                    source_link = source_text
                
                sources.append({
                    'link': source_link,
                    'display': f"- {source_link}",
                    'score': score,
                    'content': content,
                    'metadata': metadata,
                    'url': page_url,
                    'page_title': page_title,
                    'section': section,
                    'embedded_links': embedded_links
                })
        
        # Remove duplicates while preserving order
        unique_sources = []
        seen = set()
        for src in sources:
            if src['link'] not in seen:
                display(Markdown(src['display']))
                """
                # Show embedded links if present and full citations enabled
                if src['embedded_links'] and show_full_citations:
                    display(Markdown("  *Related links:*"))
                    for link in src['embedded_links']:
                        display(Markdown(f"  - [{link['text']}]({link['url']})"))
                """
                seen.add(src['link'])
                unique_sources.append(src)
        
        display(Markdown("\n*Click links for full details*"))
        
        # =================================================================
        # OPTIONAL: Full Citation Details
        # =================================================================
        if show_full_citations:
            display(Markdown("\n---"))
            display(Markdown("### **Full Citation Details**\n"))
            
            for idx, src in enumerate(unique_sources, 1):
                display(Markdown(f"""
#### Source {idx} — Relevance: {src['score']*100:.1f}%

**Page:** {src['link']}

**Content Preview:**
> {src['content'][:300]}{"..." if len(src['content']) > 300 else ""}

<details>
<summary><i>View full content</i></summary>

```
{src['content']}
```

</details>
"""))
                
                # Show embedded links
                if src['embedded_links']:
                    display(Markdown("** Embedded Links in Source:**"))
                    for link in src['embedded_links']:
                        display(Markdown(f"- [{link['text']}]({link['url']})"))
                    display(Markdown(""))
                
                # Show all metadata
                display(Markdown("**Metadata:**"))
                display(Markdown("```json\n" + json.dumps(src['metadata'], indent=2) + "\n```"))
                display(Markdown("---\n"))
    
    else:
        display(Markdown(" **No sources retrieved**"))
        if metadata_filters:
            display(Markdown("\n*Try relaxing your metadata filters or using different search terms.*"))
    
    # =================================================================
    # 4. METADATA (Optional - Only if requested)
    # =================================================================
    if show_metadata:
        display(Markdown("\n---"))
        display(Markdown("### 🔧 **Technical Metadata**\n"))
        
        display(Markdown(f"""
- **Documents retrieved:** {len(citations)}
- **Model:** `{model_id}`
- **Session ID:** `{session_id if session_id else 'None (new session)'}`
- **Number of results requested:** {number_of_results}
- **Metadata filters:** {'Applied' if metadata_filters else 'None'}
"""))
        
        # Show relevance scores
        if citations and unique_sources:
            display(Markdown("\n** Relevance Scores:**"))
            for idx, src in enumerate(unique_sources, 1):
                score = src['score']
                page_title = src['page_title']
                section = src['section']
                
                if section and section != page_title:
                    full_title = f"{page_title}: {section}"
                else:
                    full_title = page_title
                
                display(Markdown(f"- Source {idx}: **{score*100:.1f}%** — {full_title}"))
    
    display(Markdown("\n---"))
    
    return answer, citations

# ================================================================================
# ANALYSIS & EXPORT UTILITIES
# ================================================================================


def display_citations_table(citations: List[Dict]) -> pd.DataFrame:
    """
    Display citations as a pandas DataFrame for analysis.
    
    Args:
        citations: List of citation objects from chat() or ask()
    
    Returns:
        DataFrame with citation information
    
    Example:
        answer, citations = chat("How do I use Athena?")
        df = display_citations_table(citations)
        
        # Analyze the data
        print(df['Relevance %'].describe())
        high_relevance = df[df['Relevance %'].str.rstrip('%').astype(float) > 80]
    """
    if not citations:
        print("No citations to display")
        return pd.DataFrame()

    sources_data = []

    for c_idx, citation in enumerate(citations, 1):
        retrieved_refs = citation.get('retrievedReferences', [])
        
        for r_idx, ref in enumerate(retrieved_refs, 1):
            content = ref.get('content', {}).get("text", "")
            metadata = ref.get("metadata", {})

            # DEBUG: Print all available metadata keys
            print(f"\n=== Citation {c_idx} Metadata Keys ===")
            print(metadata.keys())
            print(f"Full metadata: {metadata}")
            
            # Get S3 location
            location = ref.get("location", {})
            s3_location = location.get("s3Location", {})
            s3_uri = s3_location.get("uri", "Unknown")
            source = s3_uri.split("/")[-1] if s3_uri != "Unknown" else "Unknown"
            
            # Get score
            score = ref.get('score', 0)
            
            # Get page info
            page_title = metadata.get('page_h1', 'Unknown')
            section = metadata.get('root_heading', 'N/A')
            page_url = metadata.get('page_url', 'N/A')
            
            # Count embedded links
            link_count = 0
            link_idx = 1
            while f'link_{link_idx}_text' in metadata:
                link_count += 1
                link_idx += 1
            
            sources_data.append({
                'Citation #': c_idx,
                'Page Title': page_title,
                'Section': section,
                'Relevance %': f"{score*100:.1f}%" if score else "N/A",
                'Content Length': len(content),
                'Embedded Links': link_count,
                'URL': page_url,
                'File': source
            })

    df = pd.DataFrame(sources_data)

    # Style the dataframe for better readability
    try:
        styled_df = df.style.set_properties(**{
            'text-align': 'left',
            'white-space': 'pre-wrap'
        }).set_table_styles([
            {'selector': 'th', 'props': [('background-color', '#f0f0f0'), ('font-weight', 'bold')]},
        ])
        display(styled_df)
    except:
        # Fallback if styling fails
        display(df)

    return df

def export_qa_to_markdown(
    question: str,
    answer: str,
    citations: List[Dict],
    filename: str = None
) -> str:
    """
    Export a Q&A session to a markdown file.
    
    Args:
        question: The question asked
        answer: The answer received
        citations: List of citations
        filename: Output filename (default: auto-generated with timestamp)
    
    Returns:
        The filename used
    
    Example:
        answer, citations = chat("How do I use RStudio?")
        export_qa_to_markdown("How do I use RStudio?", answer, citations, "rstudio_guide.md")
    """
    if filename is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"qa_output_{timestamp}.md"

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"# Question\n\n{question}\n\n")
        f.write(f"---\n\n")
        f.write(f"# Answer\n\n{answer}\n\n")
        f.write(f"---\n\n")
        f.write(f"# Sources\n\n")
        
        sources = []
        for citation in citations:
            retrieved_refs = citation.get('retrievedReferences', [])
            for ref in retrieved_refs:
                metadata = ref.get("metadata", {})
                page_title = metadata.get('page_h1', 'Unknown Document')
                page_url = metadata.get('page_url', '')
                section = metadata.get('root_heading', '')
                
                if section and section != page_title:
                    source_text = f"{page_title}: {section}"
                else:
                    source_text = page_title
                
                if page_url:
                    source_link = f"- [{source_text}]({page_url})"
                else:
                    source_link = f"- {source_text}"
                
                if source_link not in sources:
                    sources.append(source_link)
                
                # Add embedded links
                link_idx = 1
                while f'link_{link_idx}_text' in metadata:
                    link_text = metadata.get(f'link_{link_idx}_text')
                    link_url = metadata.get(f'link_{link_idx}_url')
                    if link_text and link_url:
                        embedded_link = f"  - Related: [{link_text}]({link_url})"
                        if embedded_link not in sources:
                            sources.append(embedded_link)
                    link_idx += 1
        
        for source in sources:
            f.write(f"{source}\n")
        
        f.write(f"\n---\n\n")
        f.write(f"*Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*\n")

    print(f"✓ Exported to {filename}")
    return filename