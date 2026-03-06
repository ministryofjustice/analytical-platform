
## 1.`tests/smoke/test_ask_smart_smoke.py`
import pytest
from helpers.apug.rag.ask_smart_07_04 import SmartAnswer
from tests.fixtures.assertions import (
    assert_retrieval_metadata_complete,
    assert_minimum_sources,
    assert_source_structure,
)

@pytest.mark.smoke
class TestAskSmartSmoke:
    """
    Smoke tests for AskSmart pipeline - quick sanity checks.
    """
    
    def test_pipeline_runs_without_error(self, ask_smart_instance):
        """Smoke Test 1: Verify pipeline runs without crashing."""
        query = "How do I delete tables?"
        result = ask_smart_instance.ask(query)
        
        assert result is not None, "Pipeline should return a result"
        assert isinstance(result, SmartAnswer), \
            f"Result should be SmartAnswer, got {type(result)}"
    
    def test_response_has_required_structure(self, ask_smart_instance):
        """Smoke Test 2: Verify response has all required fields."""
        query = "What is RStudio?"
        result = ask_smart_instance.ask(query)
        
        assert hasattr(result, 'answer'), "Result missing 'answer'"
        assert hasattr(result, 'sources'), "Result missing 'sources'"
        assert hasattr(result, 'confidence'), "Result missing 'confidence'"
        assert hasattr(result, 'retrieval_metadata'), "Result missing 'retrieval_metadata'"
        
        assert isinstance(result.answer, str), "Answer should be string"
        assert isinstance(result.sources, list), "Sources should be list"
        assert isinstance(result.confidence, (int, float)), "Confidence should be numeric"
        assert isinstance(result.retrieval_metadata, dict), "Retrieval metadata should be dict"

        assert_retrieval_metadata_complete(result)
        
        if result.sources:
            assert_source_structure(result)
    
    def test_how_to_query_returns_sources(self, ask_smart_instance):
        """Smoke Test 3: Verify how-to queries retrieve documents."""
        query = "How do I delete tables in Data Uploader?"
        result = ask_smart_instance.ask(query)
        
        assert len(result.sources) > 0, \
            "How-to query should retrieve at least one source document"
        assert result.answer, "Answer should not be empty for how-to query"
    
    def test_troubleshooting_query_processes(self, ask_smart_instance):
        """Smoke Test 4: Verify troubleshooting queries are processed."""
        query = "Why am I getting 502 errors in RStudio?"
        result = ask_smart_instance.ask(query)
        
        assert result.answer, "Troubleshooting query should produce an answer"
        
        strat = result.retrieval_metadata.get("strategy", "")
        assert strat in {"filtered", "hybrid", "broad"}, f"Unexpected strategy: {strat}"
    
    def test_empty_query_handled_gracefully(self, ask_smart_instance):
        """Smoke Test 5: Verify empty queries don't crash the pipeline."""
        result = ask_smart_instance.ask("")
        
        assert result is not None, "Pipeline should handle empty query"
        assert isinstance(result, SmartAnswer), "Should return SmartAnswer even for empty query"
        assert result.confidence <= 0.3, "Empty query should have low confidence"
    
    def test_ambiguous_query_returns_response(self, ask_smart_instance):
        """Smoke Test 6: Verify ambiguous queries get some response."""
        query = "It's not working"
        result = ask_smart_instance.ask(query)
        
        assert isinstance(result, SmartAnswer)
        assert result.answer, "Ambiguous query should still produce an answer"
    
    def test_metadata_populated(self, ask_smart_instance):
        """Smoke Test 7: Verify metadata is populated through pipeline."""
        query = "How do I use QuickSight?"
        result = ask_smart_instance.ask(query)
        
        rm = result.retrieval_metadata
        assert 'strategy' in rm, "retrieval_metadata should have 'strategy'"
        assert "docs_retrieved" in rm, "retrieval_metadata should have 'docs_retrieved'"

        assert_retrieval_metadata_complete(result)
    
    def test_confidence_in_valid_range(self, ask_smart_instance):
        """Smoke Test 8: Verify confidence scores are in valid range."""
        query = "How do I delete tables?"
        result = ask_smart_instance.ask(query)
        
        assert 0.0 <= result.confidence <= 1.0, \
            f"Confidence {result.confidence} outside valid range [0.0, 1.0]"


@pytest.mark.smoke
@pytest.mark.parametrize("query_id", ["Q1_data_uploader", "Q2_rstudio_error", "Q5_empty"])
class TestAskSmartSmokeParametrized:
    """Parametrized smoke tests for key scenarios."""
    
    def test_key_scenarios_run(self, ask_smart_instance, get_query, query_id):
        """Smoke Test 9: Verify key scenarios execute without error."""
        test_case = get_query(query_id)
        query = test_case["query"]
        
        result = ask_smart_instance.ask(query)
        
        assert result is not None
        assert isinstance(result, SmartAnswer)
        assert isinstance(result.answer, str)

        assert_retrieval_metadata_complete(result)

        print(f"✅ [{query_id}] Pipeline executed successfully")


@pytest.mark.smoke
class TestAskSmartComponentSmoke:
    """Component-level smoke tests."""
    
    def test_query_analyzer_accessible(self, ask_smart_instance):
        """Smoke Test 10: Verify QueryAnalyzer component is accessible."""
        assert hasattr(ask_smart_instance, 'analyser'), \
            "AskSmart should have 'analyser' component"
        assert ask_smart_instance.analyser is not None, \
            "QueryAnalyser should be initialized"
    
    def test_retrieval_planner_accessible(self, ask_smart_instance):
        """Smoke Test 11: Verify RetrievalPlanner component is accessible."""
        assert hasattr(ask_smart_instance, 'planner'), \
            "AskSmart should have 'planner' component"
        assert ask_smart_instance.planner is not None, \
            "RetrievalPlanner should be initialized"
    
    def test_filter_generator_accessible(self, ask_smart_instance):
        """Smoke Test 12: Verify FilterGenerator component is accessible."""
        assert hasattr(ask_smart_instance, 'filter_gen'), \
            "AskSmart should have 'filter_gen' component"
        assert ask_smart_instance.filter_gen is not None, \
            "FilterGenerator should be initialized"
    
    def test_kb_catalog_loaded(self, ask_smart_instance):
        """Smoke Test 13: Verify KB catalog is loaded."""
        assert hasattr(ask_smart_instance, 'kb_catalog'), \
            "AskSmart should have 'kb_catalog'"
        assert ask_smart_instance.kb_catalog is not None, \
            "KB catalog should be loaded"
        assert 'page_h1_list' in ask_smart_instance.kb_catalog, \
            "KB catalog should have 'page_h1_list'"


@pytest.mark.smoke
def test_smoke_suite_summary(ask_smart_instance):
    """Summary test that runs quick end-to-end check."""
    print("\n" + "="*80)
    print("SMOKE TEST SUITE SUMMARY")
    print("="*80)
    
    test_queries = [
        ("Basic How-To", "How do I delete tables?"),
        ("Troubleshooting", "502 error in RStudio"),
        ("Empty Query", ""),
    ]
    
    results = []
    for name, query in test_queries:
        try:
            result = ask_smart_instance.ask(query)
            status = "✅ PASS" if result and result.answer else "⚠️  WARN"
            results.append((name, status))
            print(f"{status} - {name}")
        except Exception as e:
            results.append((name, f"❌ FAIL: {str(e)}"))
            print(f"❌ FAIL - {name}: {str(e)}")
    
    print("="*80)
    
    assert all("FAIL" not in status for _, status in results), \
        "Some smoke tests failed - see output above"