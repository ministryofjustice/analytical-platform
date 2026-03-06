
"""
test_edge_cases_and_error_handling.py

Integration tests for robustness on edge inputs and error scenarios.

Purpose:
    Validate the chatbot’s resilience when faced with difficult or malformed
    queries. Ensures the system returns timely, traceable responses, handles
    failures gracefully, and surfaces useful diagnostics instead of crashing.

Test Coverage:
    - Very specific, broad, ambiguous, nonsense, and empty-like queries
    - Extremely long inputs and special characters
    - Presence/absence of citations and basic relevance scoring
    - Latency bounds (timeout threshold) and answer-length sanity checks
    - Error capture and structured reporting (status + message + preview)

Metrics:
    - Response Time: Per-query latency with mean/max/min summary
    - Citation Count: Number of supporting sources returned
    - Relevance Scores: Top, average, and minimum relevance (if available)
    - Answer Quality Signals: Answer length and short-answer detection
    - Status Distribution: Success / Warning / Error rates
    - Quality Issues: Aggregated flags (no citations, slow response, low relevance)

Usage:
    pytest tests/integration/edge_cases/test_edge_cases_and_error_handling.py -v -s

Notes:
    - The test logs a compact per-case report plus an overall summary table.
    - Warnings indicate suboptimal quality (e.g., no citations, low relevance, or slow responses)
      but do not fail the entire run. Errors reflect exceptions or missing answers.
    - Configure `timeout_threshold` and `number_of_results` to match SLOs and retrieval depth.
    - Requires valid credentials and access to the underlying knowledge base.
"""

import pandas as pd
from typing import  Dict, List
import numpy as np
import pytest
import time

from helpers.apug.old_rag.vector_search_05 import chat, display_citations_table, MetadataFilters


# Predefined edge case sets
@pytest.fixture(scope="module")
def edge_cases():
 return [
    {
        "name": "Very specific question",
        "question": "What is the exact syntax for DROP TABLE IF EXISTS in Athena with partition pruning?"
    },
    {
        "name": "Very broad question",
        "question": "What is AWS?"
    },
    {
        "name": "Ambiguous question",
        "question": "How do I configure it?"
    },
    {
        "name": "Nonsense question",
        "question": "How do I flibbertigibbet the quantum wombat?"
    },
    {
        "name": "Empty-like question",
        "question": "?"
    },
    {
        "name": "Very long question",
        "question": "I need to understand how to set up a comprehensive data pipeline that involves extracting data from multiple sources, transforming it using various AWS services, loading it into a data warehouse, and then creating visualizations and reports, but I'm not sure where to start or what services I should use or how they all connect together?"
    },
    {
        "name": "Special characters",
        "question": "How do I use @#$%^&*() in queries?"
    },
    {
        "name": "Code snippet in question",
        "question": "Why does SELECT * FROM table WHERE id=1; not work?"
    }
]

def test_edge_cases_and_error_handling(
    edge_cases: List[Dict[str, str]],
    number_of_results: int = 5,
    timeout_threshold: float = 30.0,
    verbose: bool = False
) -> pd.DataFrame:
    """
    Test system behavior with edge cases and error conditions.
    
    Args:
        edge_cases: List of dicts with 'name' and 'question' keys
        number_of_results: Number of results to retrieve
        timeout_threshold: Maximum acceptable response time in seconds
        verbose: Print detailed output
    
    Returns:
        DataFrame with test results for each edge case
    """
    print(f"\n{'═' * 80}")
    print("TEST: Edge Cases & Error Handling")
    print(f"{'═' * 80}")
    
    test_results = []
    
    for i, test_case in enumerate(edge_cases, 1):
        print(f"\n{'─' * 80}")
        print(f"[{i}/{len(edge_cases)}]  {test_case['name']}")
        print(f"{'─' * 80}")
        print(f"Question: '{test_case['question']}'")
        
        result = {
            'test_name': test_case['name'],
            'question': test_case['question'],
            'question_length': len(test_case['question']),
            'status': 'unknown',
            'error': None
        }
        try:
            # Measure response time
            start_time = time.time()
            
            answer, citations = chat(
                test_case['question'],
                number_of_results=number_of_results,
                verbose=False
            )
            
            elapsed_time = time.time() - start_time
            
            # Basic validation
            if answer is None:
                result['status'] = 'failed'
                result['error'] = 'No answer returned'
                print(f"  FAILED: No answer returned")
                test_results.append(result)
                continue
            
            # Process citations
            citation_count = len(citations) if citations else 0
            
            if citation_count > 0:
                df = display_citations_table(citations)
                
                if not df.empty and 'Relevance %' in df.columns:
                    scores = df['Relevance %'].str.rstrip('%').astype(float)
                    top_score = scores.iloc[0] if len(scores) > 0 else 0
                    avg_score = scores.mean()
                    min_score = scores.min()
                    
                    result['top_score'] = top_score
                    result['avg_score'] = avg_score
                    result['min_score'] = min_score
                else:
                    result['top_score'] = 0
                    result['avg_score'] = 0
                    result['min_score'] = 0
            else:
                result['top_score'] = 0
                result['avg_score'] = 0
                result['min_score'] = 0
            
            # Store metrics
            result['citation_count'] = citation_count
            result['response_time'] = elapsed_time
            result['answer_length'] = len(answer)
            result['answer_preview'] = answer[:100] + '...' if len(answer) > 100 else answer
            
            # Determine status and quality
            timeout_ok = elapsed_time <= timeout_threshold
            has_citations = citation_count > 0
            has_answer = len(answer) > 10
            
            # Quality assessment
            quality_issues = []
            
            if not has_answer:
                quality_issues.append("Answer too short")
            
            if not has_citations:
                quality_issues.append("No citations")
            
            if not timeout_ok:
                quality_issues.append(f"Slow response ({elapsed_time:.1f}s)")
            
            if has_citations and result['top_score'] < 30:
                quality_issues.append(f"Low relevance ({result['top_score']:.1f}%)")
            
            # Set status
            if quality_issues:
                result['status'] = 'warning'
                result['quality_issues'] = '; '.join(quality_issues)
            else:
                result['status'] = 'success'
                result['quality_issues'] = None
            
            # Print results
            print(f"\n    Results:")
            print(f" Status: {'✅ SUCCESS' if result['status'] == 'success' else '⚠️ WARNING'}")
            print(f" Citations: {citation_count}")
            
            if citation_count > 0:
                print(f" Top Relevance: {result['top_score']:.1f}%")
                print(f" Avg Relevance: {result['avg_score']:.1f}%")
            
            print(f" Response Time: {elapsed_time:.2f}s {'✅' if timeout_ok else '⚠️ SLOW'}")
            print(f" Answer Length: {result['answer_length']} chars")
            
            if quality_issues:
                print(f"\n   ⚠️ Quality Issues:")
                for issue in quality_issues:
                    print(f"      • {issue}")
            
            if verbose:
                print(f"\n    Answer Preview:")
                print(f" {result['answer_preview']}")
            
            # Edge case specific analysis
            if test_case['name'] == "Very specific question":
                if citation_count == 0:
                    print(f"\n    Expected: Specific questions may return no results if not documented")
                elif result['top_score'] < 50:
                    print(f"\n    Low relevance expected for very specific queries")
            
            elif test_case['name'] == "Very broad question":
                if citation_count >= number_of_results:
                    print(f"\n    Broad questions typically return max results with diverse content")
                if len(df['Section'].unique()) > citation_count * 0.7:
                    print(f"\n    High diversity detected ({len(df['Section'].unique())} sections)")
            
            elif test_case['name'] in ["Nonsense question", "Empty-like question"]:
                if citation_count == 0:
                    print(f"\n    Good: System handled invalid input gracefully")
                else:
                    print(f"\n    Warning: System returned results for nonsense/empty query")
            
        except Exception as e:
            result['status'] = 'error'
            result['error'] = str(e)
            result['response_time'] = None
            result['citation_count'] = 0
            result['answer_length'] = 0
            
            print(f"\n    ERROR: {str(e)}")
            
            if verbose:
                import traceback
                print(f"\n   Stack trace:")
                traceback.print_exc()
        
        test_results.append(result)
    
    # Create summary
    print(f"\n{'═' * 80}")
    print("EDGE CASE TEST SUMMARY")
    print(f"{'═' * 80}")
    
    results_df = pd.DataFrame(test_results)
    
    # Display summary table
    display_cols = [
        'test_name', 'status', 'citation_count', 
        'top_score', 'response_time', 'answer_length'
    ]
    available_cols = [col for col in display_cols if col in results_df.columns]
    
    print("\n" + results_df[available_cols].to_string(index=False))
    
    # Statistics
    print(f"\n{'─' * 80}")
    print(" Statistics:")
    print(f"{'─' * 80}")
    
    total_tests = len(results_df)
    success_count = len(results_df[results_df['status'] == 'success'])
    warning_count = len(results_df[results_df['status'] == 'warning'])
    error_count = len(results_df[results_df['status'] == 'error'])
    
    print(f"   Total Tests: {total_tests}")
    print(f"    Success: {success_count} ({success_count/total_tests*100:.0f}%)")
    print(f"    Warnings: {warning_count} ({warning_count/total_tests*100:.0f}%)")
    print(f"    Errors: {error_count} ({error_count/total_tests*100:.0f}%)")
    
    # Response time stats (excluding errors)
    valid_times = results_df[results_df['response_time'].notna()]['response_time']
    if len(valid_times) > 0:
        print(f"\n   Response Time:")
        print(f"      Mean: {valid_times.mean():.2f}s")
        print(f"      Max: {valid_times.max():.2f}s")
        print(f"      Min: {valid_times.min():.2f}s")
    
    # Citation stats
    print(f"\n   Citations:")
    print(f"      Mean: {results_df['citation_count'].mean():.1f}")
    print(f"      Max: {results_df['citation_count'].max()}")
    print(f"      Tests with 0 citations: {len(results_df[results_df['citation_count'] == 0])}")
    
    # Recommendations
    print(f"\n{'─' * 80}")
    print(" Recommendations:")
    print(f"{'─' * 80}")
    
    if error_count > 0:
        print(f"    {error_count} test(s) resulted in errors - review error handling")
    
    if warning_count > total_tests * 0.5:
        print(f"    High warning rate ({warning_count/total_tests*100:.0f}%) - review quality thresholds")
    
    if results_df['citation_count'].sum() == 0:
        print(f"    No citations returned for any test - check knowledge base content")
    
    if valid_times.max() > timeout_threshold:
        print(f"    Some queries exceeded timeout threshold ({timeout_threshold}s)")
    
    if success_count == total_tests:
        print(f"    All tests passed successfully!")
    
    return results_df
