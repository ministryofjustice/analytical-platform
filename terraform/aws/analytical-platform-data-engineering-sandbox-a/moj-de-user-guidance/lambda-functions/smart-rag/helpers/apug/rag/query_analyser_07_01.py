'''
Query Analyzer — System Prompt + Orchestrator (Bedrock Claude)

Analyzes a user query and **returns structured JSON** describing:
- intent & complexity
- retrieval strategy **signals** (Filtered / Hybrid / Broad / Fallback)
- suggested metadata filters (`page_h1`, `root_heading`)
- top_k & confidence
> ⚠️ The analyzer does **not** answer questions; it only routes retrieval.

---

##  What this script contains
- **`QUERY_ANALYZER_SYSTEM_PROMPT`**: production prompt defining rules, schema, examples.
- **`QueryAnalyzer`**: calls Anthropic Claude on **AWS Bedrock** and orchestrates:
  1) prompt + query → model call  
  2) robust JSON extraction (code‑fences, extra text)  
  3) parsing → `QueryAnalysis` dataclass (typed result)

---

##  Metadata model (used by filters)
- `page_h1`: exact documentation page title  
- `root_heading`: major section within the page  
- Best precision = **`page_h1` AND `root_heading` (AND logic)**

**Case handling (current setting):**
- The prompt allows case‑flexible outputs; examples use **canonical casing**.
- (Optional later) Add backend normalization to map any case → exact titles.

---

## Retrieval strategy is **guidance**, not a command
> **Retrieval strategy recommendations (Filtered / Hybrid / Broad / Fallback) are *signals*.**
> The downstream retrieval system (**filter_generator**) makes the **final choice** and runs fallback.

**Fallback sequence (suggested in downstream system):**
1. `page_h1 + root_heading`  
2. If < 3 docs → `page_h1` only  
3. If < 3 docs → `root_heading` only  
4. If < 3 docs → **no filters** (broad)

---

## I/O Schema (LLM JSON → Dataclass)
**Model output (expected):**
```json
{
  "intent": {"primary": "…"},
  "complexity": {"level": "low|medium|high"},
  "entities": {"tools_mentioned": ["…"]},
  "retrieval_strategy": {
    "recommended": "filtered|hybrid|broad",
    "suggested_top_k": 5,
    "suggested_filters": {
      "page_h1": {"equals": "…"} | {"in": ["…","…"]} | null,
      "root_heading": {"equals": "…"} | {"in": ["…","…"]} | null
    },
    "fallback_strategy": "hybrid|broad",
    "minimum_results_threshold": 3
  },
  "confidence_score": 0.0
}

'''
import os
import re
import json
import boto3
from dataclasses import dataclass
from typing import Dict, List, Optional
from config import  MODEL_ID, REGION, QUERY_ANALYSER_SYSTEM_PROMPT
print("✅ All imports work")

@dataclass
class QueryAnalysis:
    """Structured output from query analysis"""
    intent_primary: Dict[str, str] 
    complexity_level: str
    strategy: str
    confidence_score: float
    suggested_filters: Dict
    top_k: int
    tools_mentioned: List[str]
    raw_analysis: Dict

class QueryAnalyser:
    """
    Analyzes user queries to determine retrieval strategy and filters
    
    This helper encapsulates a call to an Anthropic Claude model via
    Amazon Bedrock's runtime API to obtain a structured analysis of a
    natural-language query. It then parses the response into a `QueryAnalysis`
    domain object with safe defaults and bounded values.

    Attributes:
        region (str): AWS region used for the Bedrock runtime client.
        model_id (str): The Anthropic model identifier deployed on Bedrock.
        bedrock_client: A boto3 Bedrock runtime client instance.

    """
    def __init__(self, 
                 region: str = REGION,
                 model_id: str = MODEL_ID):
        
        """Initialize a new QueryAnalyser.

        Args:
            region (str, optional): AWS region where Bedrock is available and
                the target model is deployed. Defaults to `REGION`.
            model_id (str, optional): Target Anthropic model ID on Bedrock.
                Defaults to `MODEL_ID`.

        Side Effects:
            Instantiates a boto3 Bedrock runtime client bound to the given region.

        """
        self.region = region
        self.model_id = model_id
        self.bedrock_client = boto3.client(
            service_name='bedrock-runtime',
            region_name=region
        )
    
    def analyse(self, query: str, verbose: bool = False) -> QueryAnalysis:
        """Analyze a natural-language query and return a structured result.

        This method calls a Claude model via Bedrock to get a JSON analysis,
        then parses that JSON into a `QueryAnalysis` object with sane defaults
        and bounds.

        Args:
            query (str): The user’s natural-language query to analyze.
            verbose (bool, optional): If True, prints debugging information
                during the call and parsing steps. Defaults to False.

        Returns:
            QueryAnalysis: The parsed, structured analysis capturing intent,
                complexity, suggested retrieval strategy, filters, and related fields.

        Raises:
            ValueError: If no analysis could be obtained from the model
                (e.g., empty response or parsing failure).
        """

        if verbose:
            print(f"Analyzing query: {query[:120]}...")
        analysis_json = self._call_claude(query, verbose=verbose)
        if not analysis_json:
            raise ValueError("Failed to get analysis from Claude (empty response).")
        return self._parse_analysis(analysis_json, verbose)

    def _call_claude(self, query: str, verbose: bool = False) -> Optional[Dict]:
        """
        Call the Anthropic Claude model on Bedrock to produce a JSON analysis.

        This constructs a Bedrock-compatible request body with a system prompt
        (`QUERY_ANALYSER_SYSTEM_PROMPT`) and a user message instructing the model
        to return strictly valid JSON. The method then:
        - Invokes the model via `bedrock-runtime.invoke_model`
        - Collects text content blocks
        - Strips any code fences
        - Attempts to parse the output as JSON
        - Falls back to extracting the first JSON object via regex if needed

        Args:
            query (str): The natural-language query to analyze.
            verbose (bool, optional): If True, prints diagnostics, including
                empty block warnings and raw output on failure. Defaults to False.

        Returns:
            Optional[Dict]: A dictionary parsed from the model’s JSON output, or
                None if parsing failed or the response was empty.

        Notes:
            - Expects the Bedrock response schema for Anthropic models:
              `{"content": [{"type": "text", "text": "..."}], ...}`.
            - Uses a permissive regex fallback to capture the first JSON object
              in case the model prepends/appends commentary.

        Exceptions:
            Any exception during the Bedrock call is caught and logged (if verbose),
            and the method returns None.

        """
        # Prepare the prompt for Claude
        user_message = (
            "Analyze this query and return ONLY valid JSON per the system's response schema.\n\n"
            f"Query:\n{query}\n"
        )

        # The following request body is structured for Bedrock Anthropic models
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2000,
            "temperature": 0.1,
            "system": QUERY_ANALYSER_SYSTEM_PROMPT,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": user_message}
                    ]
                }
            ],
            # Optional: guide JSON-only behavior further
            "stop_sequences": []
        }

        try:
            response = self.bedrock_client.invoke_model(
                modelId=self.model_id,
                body=json.dumps(request_body)
            )
            response_body = json.loads(response["body"].read())
            # Bedrock Anthropic returns content blocks
            blocks = response_body.get("content", [])
            if not blocks:
                if verbose:
                    print("Empty content blocks in Bedrock response.")
                return None

            # Extract concatenated text from all blocks (typically one)
            text_parts = []
            for b in blocks:
                if b.get("type") == "text" and "text" in b:
                    text_parts.append(b["text"])
            analysis_text = "\n".join(text_parts).strip()

            # Strip code fences if present
            analysis_text = self._strip_code_fences(analysis_text)

            # Try direct JSON parse
            try:
                return json.loads(analysis_text)
            except json.JSONDecodeError:
                # Fallback: extract first JSON object via regex
                match = re.search(r"\{(?:[^{}]|(?R))*\}", analysis_text, flags=re.DOTALL)
                if match:
                    candidate = match.group(0)
                    return json.loads(candidate)
                if verbose:
                    print("Failed to parse JSON. Raw model output:\n", analysis_text)
                return None

        except Exception as e:
            if verbose:
                print(f"Claude call failed: {e}")
            return None

    @staticmethod
    def _strip_code_fences(s: str) -> str:
        """
        Remove Markdown code fences from a string if present.

        This helps normalize model outputs that might include fenced
        code blocks, especially ```json or generic ``` fences.

        Args:
            s (str): The raw string potentially containing code fences.

        Returns:
            str: The input string with leading/trailing fences removed
                and whitespace trimmed.

        Examples:
            >>> QueryAnalyser._strip_code_fences("```json\\n{ \\"a\\": 1 }\\n```")
            '{ "a": 1 }'

        """
        s = s.strip()
        if s.startswith("```json"):
            s = s[len("```json"):].strip()
        if s.startswith("```"):
            s = s[len("```"):].strip()
        if s.endswith("```"):
            s = s[:-3].strip()
        return s

    def _parse_analysis(self, analysis: Dict, verbose: bool = False) -> QueryAnalysis:
        """
        Parse the model's JSON analysis into a `QueryAnalysis` object.

        Applies defensive parsing and enforces safe defaults:
        - Ensures `intent` is a dict with `primary` and `type`
        - Defaults complexity to "high" and strategy to "broad"
        - Normalizes confidence to float
        - Validates/sanitizes filter shapes (`page_h1`, `root_heading`)
        - Bounds top_k to [3, 20]
        - Coerces `tools_mentioned` to a list

        Args:
            analysis (Dict): JSON-like dictionary returned by `_call_claude`.
            verbose (bool, optional): If True, prints key parsed values and
                the raw payload on error. Defaults to False.

        Returns:
            QueryAnalysis: The structured, validated analysis object.

        Raises:
            ValueError: If required fields are missing or malformed beyond
                recovery (after applying safe defaults), including when the
                input cannot be parsed into the expected structure.
                
        """
        try:
            # Store the full intent object instead of just the primary string
            intent = analysis.get("intent", {})
            if not isinstance(intent, dict):
                intent = {"primary": "unspecified_intent", "type": "how-to"}
            
            # Ensure we have both 'primary' and 'type' keys
            intent_primary = {
                "primary": intent.get("primary", "unspecified_intent").strip() or "unspecified_intent",
                "type": intent.get("type", "how-to")
            }
            
            complexity = analysis.get("complexity", {}).get("level", "high")
            strat = analysis.get("retrieval_strategy", {}).get("recommended", "broad")
            conf = float(analysis.get("confidence_score", 0.0))
            filters = analysis.get("retrieval_strategy", {}).get("suggested_filters", {}) or {}

            # Ensure valid filter shapes (null instead of empty dicts if needed)
            page_h1 = filters.get("page_h1", None)
            root_heading = filters.get("root_heading", None)
            if page_h1 is not None and not isinstance(page_h1, dict):
                page_h1 = None
            if root_heading is not None and not isinstance(root_heading, dict):
                root_heading = None
            filters = {"page_h1": page_h1, "root_heading": root_heading}

            # Top-K bounds
            top_k = analysis.get("retrieval_strategy", {}).get("suggested_top_k", 10)
            try:
                top_k = int(top_k)
            except Exception:
                top_k = 10
            top_k = max(3, min(20, top_k))

            tools = analysis.get("entities", {}).get("tools_mentioned", []) or []
            if not isinstance(tools, list):
                tools = [str(tools)]

            if verbose:
                print(f"✅ Intent: {intent_primary}")
                print(f"✅ Complexity: {complexity}")
                print(f"✅ Strategy: {strat}")
                print(f"✅ Confidence: {conf}")
                print(f"✅ Top-K: {top_k}")
                print(f"✅ Tools: {tools}")

            return QueryAnalysis(
                intent_primary=intent_primary,
                complexity_level=complexity,
                strategy=strat,
                confidence_score=conf,
                suggested_filters=filters,
                top_k=top_k,
                tools_mentioned=tools,
                raw_analysis=analysis
            )

        except Exception as e:
            if verbose:
                print("Parse error. Raw analysis payload:\n", json.dumps(analysis, indent=2))
            raise ValueError(f"Missing or malformed field in analysis: {e}") from e
    

# Example usage:
# analyzer = QueryAnalyzer()
# analysis = analyzer.analyze("How do I set up Airflow and schedule a DAG?", verbose=True)
# print(analysis)"""
# Query Analyser for Analytical Platform User Guidance