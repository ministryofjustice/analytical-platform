"""
Retrieval Planner Module

This module converts QueryAnalysis output into concrete RetrievalPlans that guide
the retrieval system. It handles:

1. Strategy Selection: Chooses between "filtered", "hybrid", or "broad" retrieval
   based on query confidence, complexity, and detected entities.

2. Filter Validation: Optionally validates filter values against kb_catalog to
   drop invalid entries early (prevents hallucinated filters from reaching Bedrock).

3. Retrieval Budget: Sets appropriate top_k values and expansion strategies:
   - filtered: tight budget (5-10 docs), no expansion
   - hybrid: medium budget (8-15 docs), light expansion
   - broad: loose budget (15-20+ docs), aggressive expansion

4. Fallback Ladder: Defines a 4-step escalation plan when initial retrieval
   returns too few results (< min_results threshold):
   - Step 1: Try as-is (original filters + top_k)
   - Step 2: Relax root_heading filter, keep page_h1
   - Step 3: Relax page_h1 filter, keep root_heading
   - Step 4: Remove all filters (full knowledge base search)

Usage:
    analyzer = QueryAnalyzer()
    analysis = analyzer.analyze("How do I upload data?")
    
    planner = RetrievalPlanner(min_results=3, high_conf=0.75)
    plan = planner.plan(analysis, kb_catalog=catalog_dict)
    
    # plan.initial_strategy → "filtered" | "hybrid" | "broad"
    # plan.filters → validated filters for Bedrock
    # plan.budget → top_k and expansion settings
    # plan.fallback → escalation steps if needed

"""
# retrieval_planner.py
from dataclasses import dataclass, asdict, field
from typing import Optional, Dict, Any, List

# ============================================================================
# DATACLASSES (Data containers - no logic)
# ============================================================================

@dataclass
class RetrievalBudget:
    """
    Controls retrieval resource allocation.
    
    Attributes:
        top_k (int): Number of documents to retrieve initially
        expansion (str): How aggressively to expand search if needed:
                        "none" = strict (filtered strategy)
                        "light" = moderate (hybrid strategy)
                        "aggressive" = broad (broad strategy)
    """
    top_k: int
    expansion: str  # "none" | "light" | "aggressive"

@dataclass
class FallbackStep:
    """
    Single step in the fallback ladder.
    
    Attributes:
        filters (Dict): Metadata filters for this step
                       {"page_h1": {...}, "root_heading": {...}}
                       Values can be None to indicate no filtering
        top_k (int): Document count for this step (may increase from step to step)
    """
    filters: Dict[str, Optional[Dict[str, Any]]]
    top_k: int

@dataclass
class FallbackPlan:
    """
    Multi-step escalation plan when initial retrieval is insufficient.
    
    Attributes:
        min_results (int): Threshold below which fallback triggers
        ladder (List[FallbackStep]): Sequence of attempts, from strict to loose
    """
    min_results: int
    ladder: List[FallbackStep] = field(repr=False)

@dataclass
class RetrievalPlan:
    """
    Complete retrieval strategy for a single query.
    
    This is the primary output of RetrievalPlanner.plan().
    
    Attributes:
        initial_strategy (str): Primary strategy: "filtered" | "hybrid" | "broad"
        filters_allowed (bool): Whether to use filters at all (confidence-gated)
        filters (Dict): Validated filters: {"page_h1": {...}, "root_heading": {...}}
        budget (RetrievalBudget): top_k and expansion settings
        fallback (FallbackPlan): Escalation ladder if initial attempt fails
        notes (str): Observability string for debugging/logging
    """
    initial_strategy: str  # "filtered" | "hybrid" | "broad"
    filters_allowed: bool
    filters: Dict[str, Optional[Dict[str, Any]]]
    budget: RetrievalBudget
    fallback: FallbackPlan
    notes: str

# ============================================================================
# RETRIEVAL PLANNER CLASS (Logic container)
# ============================================================================

class RetrievalPlanner:
    """
    Chooses strategy, sets retrieval budget, decides filter allowance,
    defines fallback ladder. Works from QueryAnalysis semantics & confidence.
    Optionally validate filters using kb_catalog (to drop invalids early).

    
    Converts QueryAnalysis into retrieval strategies and fallback plans.
    
    Key responsibilities:
    1. Validate filter values against kb_catalog (optional but recommended)
    2. Decide initial strategy based on confidence and complexity
    3. Gate filter usage with confidence thresholds
    4. Set appropriate retrieval budgets (top_k, expansion)
    5. Build 4-step fallback ladders
    
    Confidence Thresholds:
    - high_conf (default 0.75): Use filtered strategy if confidence >= this
    - med_conf_low (default 0.5): Threshold between medium/low complexity
    - min allowed for filters in broad strategy: med_conf_low (0.5)
    - min allowed for any filters: 0.4 (prevents very uncertain filters)
    
    Attributes:
        min_results (int): Results threshold that triggers fallback (default 3)
        high_conf (float): Confidence threshold for "high" classification (default 0.75)
        med_conf_low (float): Confidence threshold between medium/low (default 0.5)
    
    """

    def __init__(self,
                 min_results: int = 3,
                 high_conf: float = 0.75,
                 med_conf_low: float = 0.5):
        """
        Initialize the RetrievalPlanner.
        
        Args:
            min_results (int): Minimum acceptable results before fallback triggers.
                             Lower = faster fallback, higher = more tolerance.
            high_conf (float): Confidence score threshold for "high confidence".
                             Queries >= this use filtered strategy if filters exist.
            med_conf_low (float): Threshold separating medium/low complexity.
                                 Queries in [med_conf_low, high_conf) use hybrid.
        """
        self.min_results = min_results
        self.high_conf = high_conf
        self.med_conf_low = med_conf_low

    def _validate_filters(self, filters: Dict[str, Any], kb_catalog: Optional[Dict]) -> Dict[str, Any]:
        """
        Optional: ensure filter values exist in catalog; else null them.
        Validate filter values against kb_catalog.
        
        Purpose: Drop invalid filter values early to prevent hallucinated filters
                from reaching Bedrock. If a filter references a non-existent page_h1
                or root_heading, this function nulls it out.
        
        Args:
            filters (Dict): Raw filters from analyzer:
                           {"page_h1": {...}, "root_heading": {...}}
                           Each can be {"equals": value} or {"in": [values]}
            kb_catalog (Optional[Dict]): Catalog with "page_h1_list" and "all_headings"
                                        If None, validation is skipped.
        
        Returns:
            Dict: Validated filters with invalid entries removed/nulled.
                 Format: {"page_h1": None or {...}, "root_heading": None or {...}}
        
        """
        if not kb_catalog:
            return filters
        
        # Build case-insensitive lookup maps
        h1_map = {x.lower(): x for x in kb_catalog.get("page_h1_list", [])}
        heading_map = {x.lower(): x for x in kb_catalog.get("all_headings", [])}

        def canon_page_h1(v):

            """Check if value(s) exist in kb_catalog['page_h1_list']."""

            if not v: 
                return None
            
            if isinstance(v, str):
                return h1_map.get(v.lower())  # ← Returns canonical casing
            
            if isinstance(v, list):
                normalized = [h1_map.get(x.lower()) for x in v if x.lower() in h1_map]
                return normalized if normalized else None
            
            return None

        def canon_root_heading(v):
            """
            Normalize root_heading values (case-insensitive).
            """
            if not v:
                return None
            if isinstance(v, str):
                return heading_map.get(v.lower())  # ← Returns canonical casing
            if isinstance(v, list):
                normalized = [heading_map.get(x.lower()) for x in v if x.lower() in heading_map]
                return normalized if normalized else None
            return None

        # Validate and normalize
        out = {"page_h1": None, "root_heading": None}
        p = filters.get("page_h1")
        r = filters.get("root_heading")

        if isinstance(p, dict):
            if "equals" in p: 
                cv = canon_page_h1(p["equals"])
                out["page_h1"] = {"equals": cv} if cv else None
            elif "in" in p:
                cv = canon_page_h1(p["in"])
                out["page_h1"] = {"in": cv} if cv else None

        if isinstance(r, dict):
            if "equals" in r:
                cv = canon_root_heading(r["equals"])
                out["root_heading"] = {"equals": cv} if cv else None
            elif "in" in r:
                cv = canon_root_heading(r["in"])
                out["root_heading"] = {"in": cv} if cv else None

        return out

    def _decide_strategy(self, analyzer_strategy: str, confidence: float,
                         tools_mentioned: List[str], filters: Dict[str, Any],
                         query_type: str = "how-to") -> str:  # ← Add query_type
        """
        Select robust retrieval strategy based on signals.
        
        Logic:
        - HIGH confidence (>= high_conf): Use filtered if filters exist, else hybrid/broad
        - MEDIUM confidence (>= med_conf_low): Use hybrid if multi-tool or only root_heading,
                                               else filtered/broad
        - LOW confidence (< med_conf_low): Always use broad (safest)
        
        Args:
            analyzer_strategy (str): Hint from QueryAnalyzer (may not be followed)
            confidence (float): Confidence score from analyzer [0.0, 1.0]
            tools_mentioned (List[str]): Tools detected in query (affects multi-tool logic)
            filters (Dict): Validated filters: {"page_h1": ..., "root_heading": ...}
            query_type (str): Query type from analyzer (policy, how-to, etc.)
        
        Returns:
            str: Selected strategy: "filtered" | "hybrid" | "broad"
        
        """
        has_page = bool(filters.get("page_h1"))
        has_root = bool(filters.get("root_heading"))

        # Policy questions always use hybrid (even if high confidence)
        if query_type == "policy":
            return "hybrid"

        if confidence >= self.high_conf:
            if has_page or has_root:
                return "filtered"
            # high confidence but no filters => hybrid if multiple tools; else broad
            return "hybrid" if len(tools_mentioned) > 1 else "broad"

        if self.med_conf_low <= confidence < self.high_conf:
            # medium confidence → hybrid if multiple tools or only root_heading
            if len(tools_mentioned) > 1 or (not has_page and has_root):
                return "hybrid"
            return "filtered" if (has_page or has_root) else "broad"

        # low confidence
        return "broad"

    def _allow_filters(self, strategy: str, confidence: float) -> bool:
        """
        Decide whether filters are allowed at all.
        Gate filter usage with confidence threshold.
        
        Purpose: Prevent very uncertain queries from using filters that might
                over-constrain the search.
        
        Logic:
        - broad strategy: Only allow if confidence >= med_conf_low (medium or higher)
        - filtered/hybrid: Allow if confidence >= 0.4 (more lenient)
        
        Args:
            strategy (str): "filtered" | "hybrid" | "broad"
            confidence (float): Confidence score [0.0, 1.0]
        
        Returns:
            bool: True if filters should be used, False to ignore them
        
        
        """
        if strategy == "broad":
            return confidence >= self.med_conf_low  # allow only if at least medium
        # filtered/hybrid
        return confidence >= 0.4  # minimal threshold to trust filters

    def _budget_for(self, strategy: str, suggested_top_k: int) -> RetrievalBudget:
        
        """
        Set retrieval budget (top_k and expansion mode) based on strategy.
        
        Budget Guidelines:
        - FILTERED: tight budget (5-10), no expansion
                   Risk: may miss relevant docs if filters too strict
                   Reward: fast, precise retrieval
        
        - HYBRID: medium budget (8-15), light expansion
                 Risk: medium; expansion as fallback
                 Reward: balanced speed/relevance
        
        - BROAD: loose budget (15-20+), aggressive expansion
                Risk: retrieves lots of docs, slower ranking
                Reward: low risk of missing relevant docs
        
        Args:
            strategy (str): "filtered" | "hybrid" | "broad"
            suggested_top_k (int): Hint from QueryAnalyzer (may be adjusted)
        
        Returns:
            RetrievalBudget: Budget object with top_k and expansion mode

        """
        if strategy == "filtered":
            k = min(10, max(5, suggested_top_k or 10))
            return RetrievalBudget(top_k=k, expansion="none")
        if strategy == "hybrid":
            k = min(15, max(8, suggested_top_k or 12))
            return RetrievalBudget(top_k=k, expansion="light")
        # broad
        k = max(15, suggested_top_k or 18)
        return RetrievalBudget(top_k=k, expansion="aggressive")

    def _fallback_ladder(self, filters_allowed: bool, filters: Dict[str, Any],
                         base_top_k: int, strategy: str) -> FallbackPlan:
        """
        Build 4-step escalation plan for when initial retrieval is insufficient.
        
        Ladder Steps (executed in order if results < min_results):
        1. Step 1: Original filters + base_top_k (as-is)
        2. Step 2: Drop root_heading, keep page_h1 + k+2 (partial relax)
        3. Step 3: Drop page_h1, keep root_heading + k+2 (alternate relax)
        4. Step 4: Drop all filters (full broad search) + k+5
        
        Each step is progressively more permissive, ensuring we don't miss
        relevant documents due to over-filtering.
        
        Args:
            filters_allowed (bool): Whether filters should be used at all
            filters (Dict): Current filters: {"page_h1": ..., "root_heading": ...}
            base_top_k (int): Starting top_k from budget
            strategy (str): Current strategy (for notes/debugging)
        
        Returns:
            FallbackPlan: Ladder with 4 steps and min_results threshold
        """
        steps: List[FallbackStep] = []

        def clone_filters(p=None, r=None):
            """Helper: create a new filter dict with given page_h1 and root_heading."""
            return {"page_h1": p, "root_heading": r}

        p = filters.get("page_h1") if filters_allowed else None
        r = filters.get("root_heading") if filters_allowed else None

        # Step 1: as-is
        steps.append(FallbackStep(filters=clone_filters(p, r), top_k=base_top_k))

        # Step 2: relax root_heading
        steps.append(FallbackStep(filters=clone_filters(p, None), top_k=min(base_top_k + 2, 15)))

        # Step 3: relax page_h1
        steps.append(FallbackStep(filters=clone_filters(None, r), top_k=min(base_top_k + 2, 15)))

        # Step 4: no filters (broad)
        steps.append(FallbackStep(filters=clone_filters(None, None), top_k=max(base_top_k + 5, 18)))

        return FallbackPlan(min_results=self.min_results, ladder=steps)

    def plan(self, analysis, kb_catalog: Optional[Dict] = None) -> RetrievalPlan:
        """
        Input: QueryAnalysis (from your analyzer).
        Output: RetrievalPlan for the retriever.
        
        Convert QueryAnalysis into a complete RetrievalPlan.
        
        This is the main entry point. It orchestrates:
        1. Filter validation against kb_catalog
        2. Strategy selection based on confidence/complexity
        3. Filter allowance gating
        4. Budget setting
        5. Fallback ladder construction
        
        Args:
            analysis: QueryAnalysis object from QueryAnalyzer.analyze()
                     Must have: strategy, confidence_score, tools_mentioned, 
                               suggested_filters, top_k
            kb_catalog (Optional[Dict]): Catalog with "page_h1_list" and "all_headings"
                                        Used to validate filters. If None, skipped.
        
        Returns:
            RetrievalPlan: Complete plan ready for retrieval system
                          - initial_strategy: Primary strategy
                          - filters_allowed: Whether filters are trusted
                          - filters: Validated filters
                          - budget: top_k and expansion settings
                          - fallback: Escalation ladder
                          - notes: Observability string
        """
        # 1) Start from analyzer signals
        filters_raw = analysis.suggested_filters or {"page_h1": None, "root_heading": None}
        # 2) Optionally validate against catalog (drop invalids early)
        filters_valid = self._validate_filters(filters_raw, kb_catalog)

        # 3)Extract query type from analyzer
        query_type = analysis.intent_primary.get("type", "how-to")

        # 4) Decide initial strategy
        strategy = self._decide_strategy(
            analyzer_strategy=analysis.strategy,
            confidence=analysis.confidence_score,
            tools_mentioned=analysis.tools_mentioned,
            filters=filters_valid,
            query_type=query_type
        )

        # 5) Decide if filters are allowed
        filters_allowed = self._allow_filters(strategy, analysis.confidence_score)
        filters_final = filters_valid if filters_allowed else {"page_h1": None, "root_heading": None}

        # 6) Budget (k, expansion)
        budget = self._budget_for(strategy, analysis.top_k)

        # 7) Fallback ladder
        fallback = self._fallback_ladder(filters_allowed, filters_final, budget.top_k, strategy)

        # 8) Notes for observability
        notes = (
            f"Strategy={strategy}; conf={analysis.confidence_score:.2f}; "
            f"filters_allowed={filters_allowed}; k={budget.top_k}"
        )

        return RetrievalPlan(
            initial_strategy=strategy,
            filters_allowed=filters_allowed,
            filters=filters_final,
            budget=budget,
            fallback=fallback,
            notes=notes
        )
