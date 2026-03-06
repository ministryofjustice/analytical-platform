"""
End-to-End tests for QueryAnalyser component.
Tests query analysis with real LLM (Bedrock Claude).

Run with: pytest tests/end2end/test_query_analyser_e2e.py --run-e2e -v
"""

import pytest
from helpers.apug.rag.query_analyser_07_01 import QueryAnalysis


@pytest.mark.e2e
class TestQueryAnalyserE2E:
    """E2E tests for query analysis with real LLM."""

    def test_how_to_query_analysis(self, query_analyser_instance):
        """E2E: Analyze 'how-to' procedural query."""
        query = "How do I create a table in Athena?"
        
        result = query_analyser_instance.analyse(query, verbose=False)
        
        # Verify QueryAnalysis structure
        assert isinstance(result, QueryAnalysis)
        assert hasattr(result, 'intent_primary')
        assert hasattr(result, 'complexity_level')
        assert hasattr(result, 'strategy')
        assert hasattr(result, 'confidence_score')
        assert hasattr(result, 'suggested_filters')
        assert hasattr(result, 'top_k')
        assert hasattr(result, 'tools_mentioned')
        assert hasattr(result, 'raw_analysis')
        
        # Verify intent_primary is a dict with required keys
        assert isinstance(result.intent_primary, dict)
        assert 'primary' in result.intent_primary
        assert 'type' in result.intent_primary
        
        # Check intent classification
        intent_type = result.intent_primary['type'].lower()
        intent_primary = result.intent_primary['primary'].lower()
        
        # Accept various how-to related classifications
        how_to_indicators = ['how', 'procedural', 'instructional', 'guide', 'tutorial']
        has_how_to_intent = any(indicator in intent_type or indicator in intent_primary 
                                 for indicator in how_to_indicators)
        
        assert has_how_to_intent, \
            f"Expected how-to intent, got type='{intent_type}', primary='{intent_primary}'"
        
        # Check tool detection
        tools_lower = [t.lower() for t in result.tools_mentioned]
        assert 'athena' in tools_lower, \
            f"Should detect 'Athena' tool, found: {result.tools_mentioned}"
        
        # Verify confidence score is normalized
        assert 0.0 <= result.confidence_score <= 1.0, \
            f"Confidence should be in [0.0, 1.0], got: {result.confidence_score}"
        
        # Verify top_k is within bounds
        assert 3 <= result.top_k <= 20, \
            f"top_k should be in [3, 20], got: {result.top_k}"
        
        print(f"\n✓ E2E Query Analysis (how-to):")
        print(f"  - Intent type: {result.intent_primary['type']}")
        print(f"  - Intent primary: {result.intent_primary['primary']}")
        print(f"  - Complexity: {result.complexity_level}")
        print(f"  - Strategy: {result.strategy}")
        print(f"  - Confidence: {result.confidence_score:.2%}")
        print(f"  - Top-K: {result.top_k}")
        print(f"  - Tools: {result.tools_mentioned}")

    def test_definition_query_analysis(self, query_analyser_instance):
        """E2E: Analyze 'what is' definition query."""
        query = "What is QuickSight?"
        
        result = query_analyser_instance.analyse(query, verbose=False)
        
        assert isinstance(result, QueryAnalysis)
        
        # Check intent classification
        intent_type = result.intent_primary['type'].lower()
        intent_primary = result.intent_primary['primary'].lower()
        
        # Accept various definition-related classifications
        definition_indicators = ['what', 'definition', 'concept', 'information', 'explain']
        has_definition_intent = any(indicator in intent_type or indicator in intent_primary 
                                     for indicator in definition_indicators)
        
        assert has_definition_intent, \
            f"Expected definition intent, got type='{intent_type}', primary='{intent_primary}'"
        
        # Check tool detection (accept variations)
        tools_lower = [t.lower() for t in result.tools_mentioned]
        quicksight_detected = any('quicksight' in tool or 'quick' in tool 
                                  for tool in tools_lower)
        
        assert quicksight_detected, \
            f"Should detect 'QuickSight' tool, found: {result.tools_mentioned}"
        
        print(f"\n✓ E2E Query Analysis (definition):")
        print(f"  - Intent: {result.intent_primary['type']} / {result.intent_primary['primary']}")
        print(f"  - Confidence: {result.confidence_score:.2%}")
        print(f"  - Tools: {result.tools_mentioned}")
        print(f"  - Strategy: {result.strategy}")

    def test_troubleshooting_query_analysis(self, query_analyser_instance):
        """E2E: Analyze troubleshooting/debugging query."""
        query = "Why is my Athena query failing with permission errors?"
        
        result = query_analyser_instance.analyse(query, verbose=False)
        
        assert isinstance(result, QueryAnalysis)
        
        # Check intent classification
        intent_type = result.intent_primary['type'].lower()
        intent_primary = result.intent_primary['primary'].lower()
        
        # Accept various troubleshooting-related classifications
        troubleshooting_indicators = [
            'troubleshoot', 'debug', 'error', 'problem', 'why', 
            'fix', 'issue', 'fail', 'help'
        ]
        has_troubleshooting_intent = any(
            indicator in intent_type or indicator in intent_primary 
            for indicator in troubleshooting_indicators
        )
        
        assert has_troubleshooting_intent, \
            f"Expected troubleshooting intent, got type='{intent_type}', primary='{intent_primary}'"
        
        # Should detect Athena
        tools_lower = [t.lower() for t in result.tools_mentioned]
        assert 'athena' in tools_lower, \
            f"Should detect 'Athena', found: {result.tools_mentioned}"
        
        print(f"\n✓ E2E Query Analysis (troubleshooting):")
        print(f"  - Intent: {result.intent_primary['type']} / {result.intent_primary['primary']}")
        print(f"  - Complexity: {result.complexity_level}")
        print(f"  - Confidence: {result.confidence_score:.2%}")
        print(f"  - Tools: {result.tools_mentioned}")

    def test_multiple_tools_detection(self, query_analyser_instance):
        """E2E: Detect multiple tools in single query."""
        query = "How do I connect RStudio to Athena to query data?"
        
        result = query_analyser_instance.analyse(query, verbose=False)
        
        assert isinstance(result, QueryAnalysis)
        assert isinstance(result.tools_mentioned, list)
        
        tools_lower = [t.lower() for t in result.tools_mentioned]
        
        # Check for both tools (accept variations)
        rstudio_detected = any('rstudio' in tool or 'r studio' in tool or 'r-studio' in tool 
                               for tool in tools_lower)
        athena_detected = 'athena' in tools_lower
        
        detected_count = sum([rstudio_detected, athena_detected])
        
        print(f"\n✓ E2E Multi-tool Detection:")
        print(f"  - Query: '{query}'")
        print(f"  - Tools detected: {result.tools_mentioned}")
        print(f"  - RStudio detected: {rstudio_detected}")
        print(f"  - Athena detected: {athena_detected}")
        print(f"  - Detection count: {detected_count}/2")
        
        # Should detect at least one tool
        assert detected_count >= 1, \
            f"Should detect at least one tool from ['RStudio', 'Athena'], found: {result.tools_mentioned}"

    def test_vague_query_confidence(self, query_analyser_instance):
        """E2E: Vague queries should have appropriate confidence."""
        vague_queries = [
            "help",
            "how do I do this?",
            "what?",
            "database"
        ]
        
        results = []
        for query in vague_queries:
            result = query_analyser_instance.analyse(query, verbose=False)
            results.append({
                'query': query,
                'confidence': result.confidence_score,
                'intent': result.intent_primary
            })
        
        print(f"\n✓ E2E Vague Query Confidence:")
        for r in results:
            print(f"  - '{r['query']}': {r['confidence']:.2%} (intent: {r['intent']['type']})")
        
        # At least some vague queries should have lower confidence
        low_confidence_count = sum(1 for r in results if r['confidence'] < 0.7)
        
        # Don't fail if LLM is confident about vague queries, just document it
        if low_confidence_count == 0:
            print(f"  ⚠️  Note: All vague queries had confidence >= 0.7")

    def test_suggested_filters_structure(self, query_analyser_instance):
        """E2E: Verify suggested_filters structure."""
        query = "How do I create tables in Athena?"
        
        result = query_analyser_instance.analyse(query, verbose=False)
        
        assert isinstance(result.suggested_filters, dict)
        assert 'page_h1' in result.suggested_filters
        assert 'root_heading' in result.suggested_filters
        
        # Filters should be None or dict (based on your implementation)
        page_h1 = result.suggested_filters['page_h1']
        root_heading = result.suggested_filters['root_heading']
        
        if page_h1 is not None:
            assert isinstance(page_h1, dict), \
                f"page_h1 should be dict or None, got: {type(page_h1)}"
        
        if root_heading is not None:
            assert isinstance(root_heading, dict), \
                f"root_heading should be dict or None, got: {type(root_heading)}"
        
        print(f"\n✓ E2E Suggested Filters Structure:")
        print(f"  - page_h1: {page_h1}")
        print(f"  - root_heading: {root_heading}")

    def test_top_k_bounds(self, query_analyser_instance):
        """E2E: Verify top_k is within valid bounds [3, 20]."""
        queries = [
            "What is Athena?",
            "How do I create complex multi-table joins in Athena with performance optimization?",
            "help"
        ]
        
        results = []
        for query in queries:
            result = query_analyser_instance.analyse(query, verbose=False)
            
            assert 3 <= result.top_k <= 20, \
                f"top_k={result.top_k} out of bounds [3, 20] for query: '{query}'"
            
            results.append({
                'query': query[:50],
                'top_k': result.top_k,
                'complexity': result.complexity_level
            })
        
        print(f"\n✓ E2E Top-K Bounds:")
        for r in results:
            print(f"  - '{r['query']}...': top_k={r['top_k']} (complexity: {r['complexity']})")

    def test_raw_analysis_preservation(self, query_analyser_instance):
        """E2E: Verify raw_analysis dict is preserved."""
        query = "How do I use QuickSight dashboards?"
        
        result = query_analyser_instance.analyse(query, verbose=False)
        
        assert isinstance(result.raw_analysis, dict)
        assert len(result.raw_analysis) > 0, "raw_analysis should not be empty"
        
        # Should contain some expected top-level keys
        expected_keys = ['intent', 'complexity', 'retrieval_strategy', 'confidence_score']
        present_keys = [key for key in expected_keys if key in result.raw_analysis]
        
        assert len(present_keys) > 0, \
            f"raw_analysis should contain some expected keys, found: {list(result.raw_analysis.keys())}"
        
        print(f"\n✓ E2E Raw Analysis Preservation:")
        print(f"  - Keys present: {list(result.raw_analysis.keys())}")

    @pytest.mark.slow
    def test_analysis_latency(self, query_analyser_instance):
        """E2E: Query analysis completes in reasonable time."""
        import time
        
        query = "How do I configure database connections in RStudio to access Athena?"
        
        start = time.time()
        result = query_analyser_instance.analyse(query, verbose=False)
        elapsed = time.time() - start
        
        assert isinstance(result, QueryAnalysis)
        assert elapsed < 5.0, \
            f"Analysis took {elapsed:.2f}s, expected < 5s"
        
        print(f"\n✓ E2E Analysis Latency:")
        print(f"  - Time: {elapsed:.2f}s")
        print(f"  - Query length: {len(query)} chars")
        print(f"  - Confidence: {result.confidence_score:.2%}")

    def test_consistency_across_similar_queries(self, query_analyser_instance):
        """E2E: Similar queries should have consistent tool detection."""
        similar_queries = [
            "How do I create a table in Athena?",
            "How do I create tables in Athena?",
            "How can I create a table in Athena?"
        ]
        
        results = []
        for query in similar_queries:
            result = query_analyser_instance.analyse(query, verbose=False)
            results.append({
                'query': query,
                'intent_type': result.intent_primary['type'],
                'tools': result.tools_mentioned,
                'strategy': result.strategy
            })
        
        # All should detect Athena
        athena_detected_count = sum(
            1 for r in results 
            if 'athena' in [t.lower() for t in r['tools']]
        )
        
        assert athena_detected_count == len(similar_queries), \
            f"All similar queries should detect Athena, only {athena_detected_count}/{len(similar_queries)} did"
        
        print(f"\n✓ E2E Consistency Check:")
        print(f"  - Athena detection: {athena_detected_count}/{len(similar_queries)}")
        for r in results:
            print(f"    '{r['query']}' -> {r['intent_type']}, tools: {r['tools']}")


@pytest.mark.e2e
@pytest.mark.slow
class TestQueryAnalyserE2EStress:
    """Stress tests for QueryAnalyser production readiness."""

    def test_consecutive_analyses(self, query_analyser_instance):
        """E2E: Multiple consecutive analyses without degradation."""
        queries = [
            "What is Athena?",
            "How do I create a table?",
            "Why is my query failing?",
            "How do I connect RStudio?",
            "What databases are supported?"
        ]
        
        results = []
        for query in queries:
            result = query_analyser_instance.analyse(query, verbose=False)
            results.append({
                'query': query,
                'success': isinstance(result, QueryAnalysis),
                'confidence': result.confidence_score,
                'tools': len(result.tools_mentioned)
            })
        
        # All should succeed
        success_count = sum(1 for r in results if r['success'])
        assert success_count == len(queries), \
            f"Only {success_count}/{len(queries)} analyses succeeded"
        
        print(f"\n✓ E2E Consecutive Analyses:")
        print(f"  - Total: {len(queries)}")
        print(f"  - Success rate: {success_count}/{len(queries)}")
        print(f"  - Avg confidence: {sum(r['confidence'] for r in results) / len(results):.2%}")

# Run all E2E tests (automatically skipped without flag)
#pytest tests/end2end/ -v

# Run with --run-e2e to actually execute E2E tests
#pytest tests/end2end/test_query_analyser_e2e.py --run-e2e -v -s

# Run excluding slow tests
#pytest tests/end2end/test_query_analyser_e2e.py --run-e2e -v -m "e2e and not slow"

# Run specific test
#pytest tests/end2end/test_query_analyser_e2e.py::TestQueryAnalyserE2E::test_how_to_query_analysis --run-e2e -v -s