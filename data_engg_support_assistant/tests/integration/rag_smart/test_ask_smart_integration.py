"""
Integration Tests for AskSmart Pipeline, DEtailed version*****

Tests the full pipeline with mocked external dependencies (LLM, KB).
These are NOT true E2E tests - they use mocks for speed and reliability.

Purpose:
    - Validate complete pipeline integration (all components work together)
    - Test with realistic query scenarios
    - Verify response structure and metadata
    - Check error handling and edge cases
    - Validate tool identification and filtering logic

What's Mocked:
    ✓ Bedrock LLM calls (for determinism and speed)
    ✓ Knowledge Base retrieval (using mock documents)
    ✓ Query analysis (using keyword-based routing)

What's Real:
    ✓ Component integration (QueryAnalyzer → Planner → FilterGenerator → AskSmart)
    ✓ Data flow between components
    ✓ Metadata propagation
    ✓ Error handling logic
    ✓ Validation logic

Difference from Smoke Tests:
    - Smoke: "Does it work at all?" (fast, basic checks)
    - Integration: "Does it work correctly?" (detailed validation)

Difference from E2E Tests:
    - Integration: Uses mocks (fast, reliable, free)
    - E2E: Real AWS calls (slow, variable, costs money)

Running:
    # Run all integration tests
    pytest tests/integration/ -v
    
    # Run specific test
    pytest tests/integration/test_ask_smart_integration.py::TestAskSmartIntegration::test_data_uploader_deletion_query -v
    
    # Run with print output
    pytest tests/integration/ -v -s
"""

# tests/integration/test_integration.py
import pytest
from helpers.apug.rag.ask_smart_07_04 import SmartAnswer

from tests.fixtures.assertions import (
    assert_retrieval_metadata_complete,
    assert_source_structure,
    assert_tools_detected,
)

@pytest.mark.integration
class TestAskSmartIntegration:
    """Integration tests for the complete AskSmart RAG pipeline."""
    
    def test_data_uploader_deletion_query(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm
    ):
        """Test Q1: Data Uploader table deletion query."""
        query = (
            "On the topic of the data uploader. "
            "Is there a process to request the removal of a table? "
            "How can I get obsolete tables deleted?"
        )
        
        result = ask_smart_instance.ask(query, verbose=False)
        
        assert isinstance(result, SmartAnswer), "Should return SmartAnswer instance"
        assert isinstance(result.answer, str), "Answer should be a string"
        assert len(result.answer) > 20, "Answer should contain meaningful content (>20 chars)"

        assert_retrieval_metadata_complete(result)
        
        assert len(result.sources) > 0, "Should return at least one source document"
        assert_source_structure(result)

        meta = result.retrieval_metadata
        assert meta["strategy"] in ["hybrid", "filtered", "broad"], f"Invalid strategy: {meta['strategy']}"
        
        assert 0.0 <= result.confidence <= 1.0, "Confidence should be normalized between 0 and 1"
        assert result.confidence > 0.5, "Mock scenario should yield reasonable confidence (>0.5)"
        
        answer_lower = result.answer.lower()
        expected_keywords = ["delete", "table", "remove", "drop"]
        assert any(kw in answer_lower for kw in expected_keywords), \
            f"Answer should mention deletion-related terms, got: {result.answer[:100]}..."
        
        assert isinstance(result.validation_issues, list), "Validation issues should be a list"
        assert len(result.validation_issues) == 0, \
            f"Should have no validation issues, found: {result.validation_issues}"
        
        assert_tools_detected(result, ["Data Uploader", "Athena"])
    
    def test_rstudio_error_query(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm
    ):
        """Test Q2: RStudio gateway error troubleshooting."""
        query = (
            "I keep getting 502 Bad Gateway errors in RStudio. "
            "Nothing is working - tried restarting, clearing cache. Help!"
        )
        
        result = ask_smart_instance.ask(query, verbose=False)
        
        assert isinstance(result, SmartAnswer)
        assert len(result.sources) >= 1, "Should find troubleshooting docs"
        assert_retrieval_metadata_complete(result)
        
        assert_tools_detected(result, ["RStudio"])
        
        answer_lower = result.answer.lower()
        error_keywords = ["502", "gateway", "error", "timeout"]
        assert any(kw in answer_lower for kw in error_keywords), \
            "Answer should reference the error code or gateway issue"
    
    def test_quicksight_schema_query(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm
    ):
        """Test Q3: QuickSight schema refresh question."""
        query = (
            "I changed the schema of my data in Athena. "
            "How do I update the schema in QuickSight without deleting datasets?"
        )
        
        result = ask_smart_instance.ask(query, verbose=False)
        
        assert isinstance(result, SmartAnswer)
        assert len(result.sources) >= 1
        assert_retrieval_metadata_complete(result)
        
        answer_lower = result.answer.lower()
        assert "quicksight" in answer_lower or "dataset" in answer_lower or "schema" in answer_lower, \
            "Answer should reference QuickSight"
        
        strategy = result.retrieval_metadata.get("strategy", "")
        assert strategy in ["hybrid", "filtered"], \
            f"Expected hybrid or filtered strategy for multi-tool query, got: {strategy}"
    
    def test_empty_query_handling(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm
    ):
        """Test Q5: Empty query edge case."""
        query = ""
        
        result = ask_smart_instance.ask(query, verbose=False)
        
        assert isinstance(result, SmartAnswer), "Should still return SmartAnswer for empty query"
        
        assert result.confidence == 0.0 or result.confidence < 0.3, \
            f"Confidence should be very low for empty query, got: {result.confidence}"
        
        assert len(result.sources) == 0 or result.answer.lower().startswith("i"), \
            "Should not return meaningful sources for empty query"
        
        assert result.answer, "Should have some response even for empty query"
    
    def test_ambiguous_query_handling(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm
    ):
        """Test Q4: Ambiguous query handling."""
        query = "It's not working, help!"
        
        result = ask_smart_instance.ask(query, verbose=False)
        print(f"\n Answer: {result.answer}") 
        
        assert isinstance(result, SmartAnswer)
        assert result.retrieval_metadata.get("strategy") == "broad", \
            "Should use broad strategy for ambiguous queries"
        
        assert result.confidence < 0.6, \
            f"Confidence should be lower for ambiguous queries, got: {result.confidence}"
        
        answer_lower = result.answer.lower()
        expected_words = ["more", "specific", "help", "information", "contact", "support", "assistance"]
        assert any(word in answer_lower for word in expected_words), \
            "Response should ask for clarification or offer help"
    
    def test_gibberish_query_handling(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm
    ):
        """Test Q6: Gibberish query edge case."""
        query = "asdfghjkl qwerty zxcvbnm 12345"
        
        result = ask_smart_instance.ask(query, verbose=False)
        
        assert isinstance(result, SmartAnswer)
        assert result.confidence < 0.3, \
            f"Gibberish should have very low confidence, got: {result.confidence}"
        
        assert result.retrieval_metadata.get("strategy") == "broad"
    
    @pytest.mark.parametrize("query_id,expected_tool", [
        ("Q1_data_uploader", "Data Uploader"),
        ("Q2_rstudio_error", "RStudio"),
        ("Q3_quicksight_schema", "QuickSight"),
        ("Q7_policy", "Infrastructure"),
        ("Q8_airflow", "Airflow"),
    ])
    def test_tool_identification(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm,
        get_query,
        query_id,
        expected_tool
    ):
        """Parametrized test: Tool identification in queries."""
        test_case = get_query(query_id)
        query = test_case["query"]
        
        result = ask_smart_instance.ask(query, verbose=False)
        
        assert_tools_detected(result, [expected_tool])

    @pytest.mark.parametrize("query_id,expected_strategy", [
        ("Q2_rstudio_error", "filtered"),
        ("Q1_data_uploader", "hybrid"),
        ("Q4_ambiguous", "broad"),
    ])
    def test_strategy_selection(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm,
        get_query,
        query_id,
        expected_strategy
    ):
        """Parametrized test: Strategy selection logic."""
        test_case = get_query(query_id)
        query = test_case["query"]
        
        result = ask_smart_instance.ask(query, verbose=False)
        
        actual_strategy = result.retrieval_metadata.get("strategy")
        assert actual_strategy == expected_strategy, \
            f"Expected '{expected_strategy}' strategy for {query_id}\nGot: '{actual_strategy}'"


@pytest.mark.integration
class TestAskSmartMetadataIntegration:
    """Integration tests focused on metadata propagation."""
    
    def test_metadata_completeness(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm
    ):
        """Test that all metadata fields are populated through the pipeline."""
        query = "How do I delete tables in Athena?"
        result = ask_smart_instance.ask(query)

        assert_retrieval_metadata_complete(result)
    
    def test_metadata_consistency(
        self,
        ask_smart_instance,
        mock_analyser,
        mock_filter_generator,
        mock_bedrock_llm
    ):
        """Test that metadata is consistent across components."""
        query = "How do I use RStudio?"
        result = ask_smart_instance.ask(query)
        
        actual_count = len(result.sources)
        metadata_count = result.retrieval_metadata.get("docs_retrieved", -1)
        assert actual_count == metadata_count, \
            f"Source count mismatch: sources={actual_count}, metadata.docs_retrieved={metadata_count}"

def print_integration_test_summary(result: SmartAnswer, query: str):
    """Helper to print detailed test results."""
    print("\n" + "="*80)
    print("INTEGRATION TEST RESULT")
    print("="*80)
    print(f"Query: {query}")
    print(f"\nAnswer: {result.answer[:200]}...")
    print(f"\nConfidence: {result.confidence:.2%}")
    print(f"Sources: {len(result.sources)}")
    print(f"Strategy: {result.retrieval_metadata.get('strategy')}")
    tools = result.retrieval_metadata.get("tools_mentioned", [])
    print(f"Tools: {tools}")
    if result.validation_issues:
        print(f"Validation Issues: {result.validation_issues}")
    print("="*80 + "\n")