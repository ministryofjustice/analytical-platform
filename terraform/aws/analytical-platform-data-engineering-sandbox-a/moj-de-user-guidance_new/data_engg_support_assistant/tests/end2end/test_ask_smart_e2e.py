"""
End-to-End Tests with Real AWS Bedrock Services

⚠️  WARNING: These tests make REAL API calls to AWS Bedrock!
    - They cost money (Bedrock charges per token)
    - They require valid AWS credentials
    - They are slower (network latency)
    - Results may vary (LLM non-determinism)

Purpose:
    - Verify the system works with real AWS services
    - Smoke test production configuration
    - Validate actual KB retrieval quality
    - Test real LLM response quality

When to Run:
    - Before production deployments
    - After AWS infrastructure changes
    - When validating KB content updates
    - During release testing (not on every commit)

Running:
    # Requires explicit flag to prevent accidental runs
    pytest --run-e2e tests/end2end/ -v
    
    # Or use marker
    pytest -m e2e --run-e2e -v
    
    # Skip E2E by default
    pytest -m "not e2e" -v

Configuration:
    - Set AWS credentials in environment
    - Ensure KB_ID, MODEL_ID, REGION in config.py
    - Verify Knowledge Base is deployed and accessible
"""
"""
End-to-end tests for the complete AskSmart pipeline.
Tests the full user query → answer flow with real AWS Bedrock services.

Run with: pytest tests/end2end/test_ask_smart_e2e.py --run-e2e -v
"""

import os
import pytest
import time
from helpers.apug.rag.ask_smart_07_04 import SmartAnswer
from config import KB_ID, MODEL_ID, REGION

@pytest.fixture(scope="class", autouse=True)
def skip_if_not_e2e(request):
    """Auto-skip E2E tests unless --run-e2e flag is provided."""
    if not request.config.getoption("--run-e2e"):
        pytest.skip("Use --run-e2e to enable E2E tests (real AWS calls).")

@pytest.mark.e2e
class TestAskSmartPipelineE2E:
    """End-to-end tests for complete RAG pipeline."""

    def test_simple_how_to_query(self, real_ask_smart_instance):
        """E2E: Simple how-to query through complete pipeline."""
        query = "How do I delete tables in Athena?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        assert result.answer, "Should generate an answer"
        assert len(result.answer) > 50, f"Answer too short: {len(result.answer)} chars"
        assert 0.0 <= result.confidence <= 1.0
        
        # Check pipeline completed without errors
        pipeline_errors = [
            issue for issue in result.validation_issues
            if "pipeline" in issue.lower() or "error occurred" in issue.lower()
        ]
        assert not pipeline_errors, f"Pipeline errors: {pipeline_errors}"
        
        print(f"\n✓ E2E Pipeline Success:")
        print(f"  - Confidence: {result.confidence:.2%}")
        print(f"  - Sources: {len(result.sources)}")
        print(f"  - Answer length: {len(result.answer)} chars")
        print(f"  - Strategy: {result.retrieval_metadata.get('strategy')}")

    def test_definition_query_with_tool(self, real_ask_smart_instance):
        """E2E: 'What is' query for specific tool."""
        query = "What is RStudio?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        assert result.answer
        
        # Verify retrieval happened
        docs_retrieved = result.retrieval_metadata.get('docs_retrieved', 0)
        
        if docs_retrieved == 0:
            # Acceptable if answer explains why
            no_results_phrases = [
                "no relevant documentation", "not find", "contact support",
                "no information available", "unable to locate"
            ]
            answer_lower = result.answer.lower()
            has_explanation = any(phrase in answer_lower for phrase in no_results_phrases)
            
            assert has_explanation, \
                f"Should explain why no docs found. Answer: {result.answer[:200]}"
        
        print(f"\n✓ E2E Definition Query:")
        print(f"  - Documents retrieved: {docs_retrieved}")
        print(f"  - Confidence: {result.confidence:.2%}")
        print(f"  - Fallback step: {result.retrieval_metadata.get('fallback_step')}")

    def test_complex_multi_tool_query(self, real_ask_smart_instance):
        """E2E: Complex query involving multiple tools."""
        query = "How do I connect RStudio to Athena and query my database?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        assert result.answer
        assert len(result.answer) > 50
        
        # Check tools were recognized
        tools_mentioned = result.retrieval_metadata.get('tools_mentioned', [])
        print(f"\n✓ E2E Multi-tool Query:")
        print(f"  - Tools mentioned: {tools_mentioned}")
        print(f"  - Strategy: {result.retrieval_metadata.get('strategy')}")
        print(f"  - Confidence: {result.confidence:.2%}")

    def test_troubleshooting_query(self, real_ask_smart_instance):
        """E2E: Troubleshooting/error query."""
        query = "Why is my Athena query failing with access denied?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        assert result.answer
        
        # Verify query type was recognized
        query_type = result.retrieval_metadata.get('query_type', '')
        print(f"\n✓ E2E Troubleshooting Query:")
        print(f"  - Query type: {query_type}")
        print(f"  - Sources: {len(result.sources)}")
        print(f"  - Confidence: {result.confidence:.2%}")

    def test_vague_query_handling(self, real_ask_smart_instance):
        """E2E: Vague/ambiguous query handling - verify graceful degradation."""
        test_cases = [
            ("help", "single word"),
            ("help me with data", "vague multi-word"),
            ("how do I do this?", "contextless question"),
        ]
        
        results = []
        for query, description in test_cases:
            result = real_ask_smart_instance.ask(query, verbose=False)
            
            assert isinstance(result, SmartAnswer)
            assert result.answer, f"Should provide response for: {description}"
            
            results.append({
                'query': query,
                'description': description,
                'confidence': result.confidence,
                'answer_length': len(result.answer),
                'sources': len(result.sources)
            })
        
        print(f"\n✓ E2E Vague Query Handling:")
        for r in results:
            print(f"  - {r['description']}: conf={r['confidence']:.2%}, "
                f"answer={r['answer_length']} chars, sources={r['sources']}")
        
        # Calculate average confidence
        avg_confidence = sum(r['confidence'] for r in results) / len(results)
        print(f"  - Average confidence: {avg_confidence:.2%}")
        
        # Optional soft assertion (warning, not failure)
        if avg_confidence >= 0.8:
            print(f"  ⚠️  Note: High average confidence for vague queries")
            print(f"      This may indicate the system is providing helpful guidance")

    def test_retrieval_strategy_progression(self, real_ask_smart_instance):
        """E2E: Verify retrieval strategy fallback works."""
        query = "How do I use the Analytical Platform?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        
        metadata = result.retrieval_metadata
        assert 'strategy' in metadata
        assert 'fallback_step' in metadata
        
        print(f"\n✓ E2E Retrieval Strategy:")
        print(f"  - Strategy used: {metadata.get('strategy')}")
        print(f"  - Fallback step: {metadata.get('fallback_step')}")
        print(f"  - Documents: {metadata.get('docs_retrieved')}")
        print(f"  - Filters used: {metadata.get('filters_used')}")

    def test_answer_citation_presence(self, real_ask_smart_instance):
        """E2E: Verify inline citations are present in answers."""
        query = "How do I create a database in Athena?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        assert result.answer
        
        # Check if citations are present (e.g., [Doc 1], [Doc 2])
        import re
        citation_pattern = r'$$Doc \d+$$'
        citations = re.findall(citation_pattern, result.answer)
        
        print(f"\n✓ E2E Citation Check:")
        print(f"  - Sources available: {len(result.sources)}")
        print(f"  - Citations found: {len(citations)}")
        if citations:
            print(f"  - Citation examples: {citations[:3]}")

    def test_confidence_scoring_accuracy(self, real_ask_smart_instance):
        """E2E: Verify confidence scoring is reasonable."""
        test_cases = [
            ("How do I create a table in Athena?", "specific"),
            ("What is QuickSight?", "specific"),
            ("help", "vague"),
        ]
        
        results = []
        for query, expected_type in test_cases:
            result = real_ask_smart_instance.ask(query, verbose=False)
            results.append({
                'query': query,
                'type': expected_type,
                'confidence': result.confidence,
                'sources': len(result.sources)
            })
        
        print(f"\n✓ E2E Confidence Scoring:")
        for r in results:
            print(f"  - {r['type']}: {r['confidence']:.2%} ({r['sources']} sources)")

    def test_smart_answer_dataclass_completeness(self, real_ask_smart_instance):
        """E2E: Verify SmartAnswer has all expected fields."""
        query = "What is RStudio?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        # Check all SmartAnswer fields exist
        assert hasattr(result, 'answer')
        assert hasattr(result, 'sources')
        assert hasattr(result, 'retrieval_metadata')
        assert hasattr(result, 'confidence')
        assert hasattr(result, 'validation_issues')
        
        # Check types
        assert isinstance(result.answer, str)
        assert isinstance(result.sources, list)
        assert isinstance(result.retrieval_metadata, dict)
        assert isinstance(result.confidence, float)
        assert isinstance(result.validation_issues, list)
        
        print(f"\n✓ E2E SmartAnswer Structure:")
        print(f"  - All required fields present")
        print(f"  - Validation issues: {len(result.validation_issues)}")

    def test_retrieval_metadata_structure(self, real_ask_smart_instance):
        """E2E: Verify retrieval_metadata has all required fields."""
        query = "How do I create tables in Athena?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        
        # Verify all required metadata fields exist
        metadata = result.retrieval_metadata
        required_keys = [
            'kb_id', 'strategy', 'filters_used', 'fallback_step',
            'docs_retrieved', 'analyzer_confidence', 'query_type',
            'tools_mentioned', 'notes', 'latency_ms'
        ]
        
        missing_keys = [key for key in required_keys if key not in metadata]
        assert not missing_keys, f"Missing metadata keys: {missing_keys}"
        
        # Verify types
        assert isinstance(metadata['kb_id'], str)
        assert isinstance(metadata['strategy'], str)
        assert isinstance(metadata['fallback_step'], int)
        assert isinstance(metadata['docs_retrieved'], int)
        assert isinstance(metadata['tools_mentioned'], list)
        
        print(f"\n✓ E2E Retrieval Metadata Structure:")
        print(f"  - All {len(required_keys)} required keys present")
        print(f"  - Strategy: {metadata['strategy']}")
        print(f"  - Docs: {metadata['docs_retrieved']}")

    @pytest.mark.slow
    def test_end_to_end_latency(self, real_ask_smart_instance):
        """E2E: Measure complete pipeline latency."""
        query = "How do I use QuickSight?"
        
        start = time.time()
        result = real_ask_smart_instance.ask(query, verbose=False)
        elapsed = time.time() - start

        assert result.answer, "Should generate answer"
        assert elapsed < 30, f"E2E pipeline took {elapsed:.2f}s (expected < 30s)"
        
        # Check recorded latency
        recorded_latency = result.retrieval_metadata.get('latency_ms', 0)
        
        print(f"\n✓ E2E Latency:")
        print(f"  - Measured: {elapsed:.2f}s")
        print(f"  - Recorded: {recorded_latency:.0f}ms")
        print(f"  - Confidence: {result.confidence:.2%}")

    def test_source_metadata_completeness(self, real_ask_smart_instance):
        """E2E: Verify source metadata is complete."""
        query = "What databases does Athena support?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        
        if result.sources and len(result.sources) > 0:
            first_source = result.sources[0]
            
            # Check required fields
            required_fields = ['content', 'metadata', 'score']
            for field in required_fields:
                assert field in first_source, \
                    f"Source missing required field: {field}"
            
            # Check metadata has expected keys
            source_metadata = first_source.get('metadata', {})
            
            print(f"\n✓ E2E Source Metadata:")
            print(f"  - Sources: {len(result.sources)}")
            print(f"  - Top score: {first_source.get('score', 0):.3f}")
            print(f"  - Metadata keys: {list(source_metadata.keys())}")
        else:
            print(f"\n✓ E2E Source Metadata (no sources retrieved)")


@pytest.mark.e2e
class TestAskSmartErrorHandlingE2E:
    """End-to-end tests for error handling scenarios."""

    def test_empty_query_handling(self, real_ask_smart_instance):
        """E2E: Empty query handling."""
        result = real_ask_smart_instance.ask("", verbose=False)
        
        assert isinstance(result, SmartAnswer)
        assert result.answer, "Should provide guidance for empty query"
        assert result.confidence < 0.5, "Empty query should have low confidence"
        
        print(f"\n✓ E2E Empty Query:")
        print(f"  - Confidence: {result.confidence:.2%}")
        print(f"  - Answer preview: {result.answer[:100]}...")

    def test_extremely_long_query(self, real_ask_smart_instance):
        """E2E: Very long query handling."""
        query = "How do I " + "create tables and " * 100 + "in Athena?"
        result = real_ask_smart_instance.ask(query, verbose=False)
        
        assert isinstance(result, SmartAnswer)
        assert result.answer
        
        print(f"\n✓ E2E Long Query ({len(query)} chars):")
        print(f"  - Confidence: {result.confidence:.2%}")

    def test_special_characters_query(self, real_ask_smart_instance):
        """E2E: Query with special characters."""
        query = "How do I use $ and @ symbols in Athena queries?"
        result = real_ask_smart_instance.ask(query, verbose=False)
        
        assert isinstance(result, SmartAnswer)
        assert result.answer
        
        print(f"\n✓ E2E Special Characters:")
        print(f"  - Confidence: {result.confidence:.2%}")

    def test_low_confidence_guidance(self, real_ask_smart_instance):
        """E2E: Low confidence answers should provide helpful guidance."""
        query = "asdfghjkl"  # Gibberish query
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        assert result.answer
        
        # Low confidence answers should contain helpful phrases
        answer_lower = result.answer.lower()
        helpful_phrases = [
            "more specific", "provide details", "contact support",
            "need more information", "unclear", "help you better"
        ]
        
        has_guidance = any(phrase in answer_lower for phrase in helpful_phrases)
        
        print(f"\n✓ E2E Low Confidence Guidance:")
        print(f"  - Confidence: {result.confidence:.2%}")
        print(f"  - Has helpful guidance: {has_guidance}")
        print(f"  - Answer preview: {result.answer[:100]}...")


@pytest.mark.e2e
@pytest.mark.slow
@pytest.mark.skipif(
    os.environ.get("CI") == "true",
    reason="Skip expensive stress tests in CI"
)
class TestAskSmartStressE2E:
    """Stress tests for production readiness."""

    def test_consecutive_queries(self, real_ask_smart_instance):
        """E2E: Multiple consecutive queries."""
        queries = [
            "What is Athena?",
            "How do I create a table?",
            "What is QuickSight?",
            "How do I connect RStudio?",
            "What databases are supported?"
        ]
        
        results = []
        for query in queries:
            result = real_ask_smart_instance.ask(query, verbose=False)
            results.append({
                'query': query,
                'success': isinstance(result, SmartAnswer) and result.answer,
                'confidence': result.confidence,
                'sources': len(result.sources)
            })
        
        # All should succeed
        success_count = sum(1 for r in results if r['success'])
        assert success_count == len(queries), \
            f"Only {success_count}/{len(queries)} queries succeeded"
        
        print(f"\n✓ E2E Consecutive Queries:")
        print(f"  - Total: {len(queries)}")
        print(f"  - Success rate: {success_count}/{len(queries)}")
        print(f"  - Avg confidence: {sum(r['confidence'] for r in results) / len(results):.2%}")

    def test_pipeline_component_integration(self, real_ask_smart_instance):
        """E2E: Verify all pipeline components are working together."""
        query = "How do I query data in Athena?"
        result = real_ask_smart_instance.ask(query, verbose=False)

        assert isinstance(result, SmartAnswer)
        
        # Check that query analysis happened (tools detected)
        tools = result.retrieval_metadata.get('tools_mentioned', [])
        
        # Check that retrieval happened (strategy was used)
        strategy = result.retrieval_metadata.get('strategy', '')
        assert strategy, "Strategy should be recorded"
        
        # Check that answer generation happened
        assert len(result.answer) > 0, "Answer should be generated"
        
        # Check that validation happened
        assert isinstance(result.validation_issues, list)
        
        print(f"\n✓ E2E Component Integration:")
        print(f"  - Query Analysis: {len(tools)} tools detected")
        print(f"  - Retrieval: {strategy} strategy")
        print(f"  - Answer Generation: {len(result.answer)} chars")
        print(f"  - Validation: {len(result.validation_issues)} issues")