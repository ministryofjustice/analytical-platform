"""
Specialized Assertion Helpers

Domain-specific assertions for AskSmart testing.
"""

from typing import Any, List

class ResponseAssertions:
    """Collection of specialized assertions for SmartAnswer responses."""
    
    @staticmethod
    def assert_retrieval_metadata_complete(response):
        """
        Validate retrieval metadata has required fields and values consistent
        with the current AskSmart schema.

        Requires:
          - retrieval_metadata: dict
          - fields: 'strategy', 'docs_retrieved'
          - docs_retrieved must equal len(sources)
          - optional fields (if present): fallback_step >= 0, latency_ms >= 0

        """
        rm = response.retrieval_metadata
        assert isinstance(rm, dict), "retrieval_metadata must be a dict"
        
        required = ["strategy", "docs_retrieved"]
        for field in required:
            assert field in rm, f"retrieval_metadata missing '{field}'"
        
        # Validate strategy is valid
        valid_strategies = ["filtered", "hybrid", "broad"]
        assert rm["strategy"] in valid_strategies, \
            f"Invalid strategy: {rm['strategy']}, must be one of {valid_strategies}"
        
        # Count should match sources length
        assert rm["docs_retrieved"] == len(response.sources), \
            f"Metadata docs_retrieved ({rm["docs_retrieved"]}) doesn't match sources ({len(response.sources)})"
        

        #Optional fields sanity (do not fail if missing)
        if "fallback_step" in rm:
            assert isinstance(rm["fallback_step"], int) and rm["fallback_step"] >= 0, \
                "fallback_step must be a non-negative int"
        if "latency_ms" in rm:
            assert isinstance(rm["latency_ms"], (int, float)) and rm["latency_ms"] >= 0, \
                "latency_ms must be >= 0"

    
    @staticmethod
    def assert_tools_detected(response, expected_tools: List[str]):
        """Assert specific tools were detected."""
        # Handle both query_metadata and retrieval_metadata
        query_tools = getattr(response, 'query_metadata', {}).get("tools_mentioned", [])
        retrieval_tools = response.retrieval_metadata.get("tools_mentioned", [])
        
        all_tools = [str(t).lower() for t in query_tools + retrieval_tools]
        
        for tool in expected_tools:
            assert any(tool.lower() in t for t in all_tools), \
                f"Expected tool '{tool}' not detected. Found: {query_tools + retrieval_tools}"
    
    @staticmethod
    def assert_minimum_sources(response, min_count: int):
        """Assert response has at least minimum number of sources."""
        actual = len(response.sources)
        assert actual >= min_count, \
            f"Expected at least {min_count} sources, got {actual}"
    
    @staticmethod
    def assert_source_structure(response):
        """
        Validate all sources have required structure.
        - 'content' text
        - 'metadata' dict with 'page_h1' and 'root_heading'
          (Also accepts top-level page_h1/root_heading fields)
        """
        for i, source in enumerate(response.sources):
            assert isinstance(source, dict), f"Source {i} must be a dict"
            
            assert "content" in source and isinstance(source["content"], str), \
                f"Source {i} missing 'content' string"

            meta = source.get("metadata", {})
        
            # Check canonical format (nested metadata)
            has_nested = (
                isinstance(meta, dict) and 
                "page_h1" in meta and 
                "root_heading" in meta
            )
            
            # Check legacy format (top-level fields)
            has_top_level = (
                "page_h1" in source and 
                "root_heading" in source
            )
            
            assert has_nested or has_top_level, (
                f"Source {i} missing required metadata. "
                f"Expected either:\n"
                f"  - metadata.page_h1 and metadata.root_heading (canonical), or\n"
                f"  - top-level page_h1 and root_heading (legacy)"
            )
            
            # Validate non-empty values
            page_h1 = meta.get("page_h1") or source.get("page_h1")
            root_heading = meta.get("root_heading") or source.get("root_heading")
            
            assert page_h1 and isinstance(page_h1, str), \
                f"Source {i} page_h1 must be non-empty string"
            assert root_heading and isinstance(root_heading, str), \
                f"Source {i} root_heading must be non-empty string"


# Make functions available at module level
assert_retrieval_metadata_complete = ResponseAssertions.assert_retrieval_metadata_complete
assert_tools_detected = ResponseAssertions.assert_tools_detected
assert_minimum_sources = ResponseAssertions.assert_minimum_sources
assert_source_structure = ResponseAssertions.assert_source_structure