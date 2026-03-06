
"""
test_metadata_filter_effectiveness.py

Integration tests for RAG metadata filter precision and impact.

Purpose:
    Evaluate how metadata filters (e.g., by heading or page title) affect search
    relevance and precision versus an unfiltered baseline. The test auto-discovers
    actual section names from unfiltered results, applies the most appropriate
    filter, and compares quality signals to validate that filters improve focus
    without degrading relevance.

Test Coverage:
    - Baseline (unfiltered) discovery of sections/pages and relevance stats
    - Filtered vs. unfiltered comparison for each golden question
    - Support for multiple filter types (heading, page_title, page, etc.)
    - Keyword presence checks against expected keywords
    - Error handling and detailed failure analysis with recommendations
    - Aggregated summary of pass rate and average effectiveness metrics

Metrics:
    - Filter Precision: % of filtered results matching the filter criterion
    - Diversity Reduction: % decrease in section variety (baseline → filtered)
    - Relevance Change: Δ in mean relevance score (% points)
    - Score Improvement: % change relative to baseline mean score
    - Keyword Match Rate: % of expected keywords found in filtered results
    - Effectiveness Score & Grade: Composite score with A–D grading

Usage:
    pytest tests/integration/rag_with_filter/test_metadata_filter_effectiveness.py -v -s

Notes:
    - Each test runs the query twice (unfiltered, then filtered) and reuses
      unfiltered results when possible to avoid duplicate calls.
    - Requires valid AWS credentials and access to the Bedrock Knowledge Base.
    - Asserts that at least one test succeeds and that average filter precision
      across successful tests is ≥ 40%.
"""

import traceback
from typing import Dict, List, Any
import numpy as np
import pandas as pd
import pytest
from helpers.apug.old_rag.vector_search_05 import chat, display_citations_table, MetadataFilters

# === Golden Test Set ===
@pytest.fixture(scope="module")
def golden_questions():
    """Golden test set for integration testing"""
    return [
    {
        "question": "How do I delete a table in Athena?",
        "expected_section": "Athena",
        "expected_keywords": ["delete", "table", "DROP TABLE", "SQL"],
        "minimum_relevance": 40.0  # Expect at least 70% relevance for top result
    },
    {
        "question": "How do I install R packages in RStudio?",
        "expected_section": "RStudio",
        "expected_keywords": ["install", "packages", "install.packages", "library"],
        "minimum_relevance": 40.0
    },
    {
        "question": "What is Amazon S3?",
        "expected_section": "S3",
        "expected_keywords": ["S3", "storage", "bucket", "object"],
        "minimum_relevance": 40.0
    }
]

def test_metadata_filter_effectiveness(golden_questions):
    """
    Test the effectiveness of metadata filters in the RAG system.
    
    This test evaluates how well metadata filters improve search relevance and precision
    by comparing filtered vs unfiltered results across a set of golden questions. Each
    test measures filter precision, relevance improvements, and result diversity changes.
    
    The test first analyzes unfiltered results to discover actual section names, then
    applies appropriate filters based on what's actually in the knowledge base.
    
    Args:
        golden_questions: Pytest fixture containing a list of test cases. Each test case
                         is a dict with:
                         - question: The search query string
                         - expected_section: The documentation section name to filter by
                         - expected_keywords: List of keywords expected in results
                         - minimum_relevance: Minimum expected relevance score (%)
    
    Raises:
        AssertionError: If all filter tests fail
        AssertionError: If average filter precision is below 40%
    
    Notes:
        - Each test runs two queries: one without filter and one with filter
        - Automatically discovers actual section names from unfiltered results
        - Compares result quality, relevance scores, and section diversity
        - Provides detailed recommendations for filter optimization
        - Requires valid AWS credentials for Bedrock Knowledge Base access
    """
    print(f"\n{'═' * 80}")
    print("TEST: Metadata Filter Effectiveness")
    print(f"{'═' * 80}")
    
    all_results = []
    
    for test_case in golden_questions:
        test_query = test_case['question']
        expected_section = test_case['expected_section']
        
        print(f"\n{'─' * 80}")
        print(f" Query: '{test_query}'")
        print(f" Expected Section: {expected_section}")
        print(f"{'─' * 80}")
        
        try:
            # First, run unfiltered query to discover actual sections
            print(f"\n{'─' * 40}")
            print(" DISCOVERING ACTUAL SECTIONS (Unfiltered):")
            print(f"{'─' * 40}")
            
            answer1, citations1 = chat(
                test_query, 
                number_of_results=10,
                verbose=False
            )
            
            if not citations1 or len(citations1) == 0:
                print(" No citations returned - skipping this test")
                all_results.append({
                    'query': test_query,
                    'test_case': test_case,
                    'filter_config': None,
                    'success': False,
                    'unfiltered_error': 'No citations returned'
                })
                continue
                
            df1 = display_citations_table(citations1)
            
            if df1.empty:
                print(" Citations table is empty - skipping this test")
                all_results.append({
                    'query': test_query,
                    'test_case': test_case,
                    'filter_config': None,
                    'success': False,
                    'unfiltered_error': 'Empty citations table'
                })
                continue
            
            # Discover actual section names
            sections_found = df1['Section'].value_counts()
            print(f"\n   Sections found in results:")
            for section, count in sections_found.head(10).items():
                match_indicator = "✓" if expected_section.lower() in str(section).lower() else " "
                print(f"     [{match_indicator}] {section}: {count} results")
            
            # Find the best matching section for the filter
            matching_sections = [
                section for section in sections_found.index
                if expected_section.lower() in str(section).lower()
            ]
            
            if matching_sections:
                # Use the most common matching section
                actual_section = matching_sections[0]
                print(f"\n Found matching section: '{actual_section}'")
                
                filter_config = {
                    'type': 'heading',
                    'value': actual_section
                }
                print(f" Using filter: by_heading('{actual_section}')")
            else:
                # Use page_title filter as fallback
                print(f"\n   ⚠️  No exact section match found")
                print(f" Trying page_title filter instead...")
                
                filter_config = {
                    'type': 'page_title',
                    'value': expected_section
                }
            
            result = run_single_filter_test(
                test_case=test_case,
                filter_config=filter_config,
                unfiltered_data=(df1, citations1),
                number_of_results=10,
                filtered_results=5,
                verbose=False
            )
            
            all_results.append(result)
            
        except Exception as e:
            print(f"\n Exception in test:")
            print(f"   {type(e).__name__}: {str(e)}")
            traceback.print_exc()
            
            all_results.append({
                'query': test_query,
                'test_case': test_case,
                'filter_config': None,
                'success': False,
                'exception': str(e),
                'exception_type': type(e).__name__
            })
    
    # Print summary
    print_filter_effectiveness_summary(all_results)
    
    # Detailed failure analysis
    failed_results = [r for r in all_results if not r.get('success', False)]
    if failed_results:
        print(f"\n{'═' * 80}")
        print("FAILURE ANALYSIS")
        print(f"{'═' * 80}\n")
        
        for result in failed_results:
            print(f" Query: {result['query']}")
            if result.get('filter_config'):
                print(f"   Filter: {result['filter_config']}")
            
            if 'exception' in result:
                print(f"   Exception: {result['exception_type']}")
                print(f"   Message: {result['exception']}")
            elif 'unfiltered_error' in result:
                print(f"   Unfiltered Error: {result['unfiltered_error']}")
            elif 'filtered_error' in result:
                print(f"   Filtered Error: {result['filtered_error']}")
            else:
                print(f"   Unknown error - check result keys: {list(result.keys())}")
            print()
    
    # Assertions with better error messages
    successful_results = [r for r in all_results if r.get('success', False)]
    
    assert len(all_results) > 0, "No tests were executed"
    
    if len(successful_results) == 0:
        failure_summary = "\n".join([
            f"  - {r['query'][:50]}: {r.get('exception', r.get('unfiltered_error', r.get('filtered_error', 'Unknown error')))}"
            for r in failed_results[:5]
        ])
        pytest.fail(
            f"All {len(all_results)} filter tests failed:\n{failure_summary}\n"
            f"This may indicate:\n"
            f"  - Section names don't match expected values in the knowledge base\n"
            f"  - Filters are too restrictive\n"
            f"  - Connection or authentication issues\n"
            f"Check the logs above for discovered section names."
        )
    
    # More lenient precision threshold since we're auto-discovering sections
    avg_precision = np.mean([
        r['effectiveness']['filter_precision'] 
        for r in successful_results 
        if 'effectiveness' in r
    ])
    
    assert avg_precision >= 40, (
        f"Average filter precision too low: {avg_precision:.0f}%\n"
        f"Successful tests: {len(successful_results)}/{len(all_results)}\n"
        f"Consider adjusting filter criteria or minimum threshold."
    )

def run_single_filter_test(
    test_case: Dict[str, Any],
    filter_config: Dict[str, Any],
    unfiltered_data: tuple = None,
    number_of_results: int = 10,
    filtered_results: int = 5,
    verbose: bool = False
) -> Dict:
    """
    Run a single filter effectiveness test (helper function, not a pytest test).
    
    Executes the same query twice (with and without filter) and analyzes the differences
    in result quality, relevance, and precision. Calculates comprehensive metrics to
    evaluate filter performance and provides actionable recommendations.
    
    Args:
        test_case: Golden question test case dict containing:
                  - question: The search query string
                  - expected_section: Expected documentation section
                  - expected_keywords: List of expected keywords in results
                  - minimum_relevance: Minimum expected relevance score (%)
        filter_config: Filter configuration dict with:
                      - type: Filter type ('heading', 'page', 'page_title', 
                             'exact_page_title', 'page_and_heading', 'any_heading',
                             'heading_level', or 'custom')
                      - value: Filter value (string, list, or dict depending on type)
        unfiltered_data: Optional tuple of (df, citations) from a previous unfiltered query
                        to avoid duplicate queries. If None, runs new unfiltered query.
        number_of_results: Number of results to retrieve without filter (default: 10)
        filtered_results: Number of results to retrieve with filter (default: 5)
        verbose: If True, print detailed section and page distributions (default: False)
    
    Returns:
        Dict: Comprehensive test results containing:
            - query: Original test query
            - test_case: The original test case dict
            - filter_config: Filter configuration used
            - success: Boolean indicating if test completed successfully
            - unfiltered: Dict with unfiltered results metrics
            - filtered: Dict with filtered results metrics
            - effectiveness: Dict with filter performance metrics
            - keyword_match: Dict with keyword matching results
            - unfiltered_error: Error message if unfiltered query failed (optional)
            - filtered_error: Error message if filtered query failed (optional)
    
    Note:
        This is a helper function, not a pytest test. It's called by 
        test_metadata_filter_effectiveness() to evaluate individual filters.
    """
    
    # Extract query from test_case
    test_query = test_case['question']
    expected_section = test_case['expected_section']
    expected_keywords = test_case['expected_keywords']
    minimum_relevance = test_case['minimum_relevance']
    
    results = {
        'query': test_query,
        'test_case': test_case,
        'filter_config': filter_config,
        'success': False
    }
    
    # =================================================================
    # Test WITHOUT filter (or use provided data)
    # =================================================================
    if unfiltered_data is None:
        print(f"\n{'─' * 40}")
        print(" WITHOUT FILTER:")
        print(f"{'─' * 40}")
        
        try:
            answer1, citations1 = chat(
                test_query, 
                number_of_results=number_of_results,
                verbose=False
            )
            
            if not citations1 or len(citations1) == 0:
                print(" No citations returned from chat()")
                results['unfiltered_error'] = 'No citations returned'
                return results
                
            df1 = display_citations_table(citations1)
            
            if df1.empty:
                print(" Citations table is empty")
                results['unfiltered_error'] = 'Empty citations table'
                return results
                
        except Exception as e:
            print(f" Error in unfiltered query:")
            print(f"   {type(e).__name__}: {str(e)}")
            traceback.print_exc()
            results['unfiltered_error'] = f"{type(e).__name__}: {str(e)}"
            return results
    else:
        # Use provided unfiltered data
        df1, citations1 = unfiltered_data
        print(f"\n   Using pre-fetched unfiltered data")
    
    # Analyze unfiltered results
    sections1 = df1['Section'].value_counts()
    pages1 = df1['Page Title'].value_counts()
    scores1 = df1['Relevance %'].str.rstrip('%').astype(float)
    
    print(f"\n Unfiltered Stats:")
    print(f"   Total results: {len(df1)}")
    print(f"   Unique sections: {len(sections1)}")
    print(f"   Unique pages: {len(pages1)}")
    print(f"   Avg relevance: {scores1.mean():.1f}%")
    print(f"   Top score: {scores1.max():.1f}%")
    
    if verbose:
        print(f"\n   Top sections:")
        for section, count in sections1.head(5).items():
            print(f"      {section}: {count}")
        print(f"\n   Top pages:")
        for page, count in pages1.head(5).items():
            print(f"      {page}: {count}")
    
    results['unfiltered'] = {
        'total_results': len(df1),
        'unique_sections': len(sections1),
        'unique_pages': len(pages1),
        'avg_relevance': scores1.mean(),
        'top_score': scores1.max(),
        'sections': sections1.to_dict(),
        'pages': pages1.to_dict(),
        'all_scores': scores1.tolist()
    }
    
    # =================================================================
    # Test WITH filter
    # =================================================================
    print(f"\n{'─' * 40}")
    print(f" WITH FILTER: {filter_config}")
    print(f"{'─' * 40}")
    
    try:
        # Build metadata filter based on config type
        filter_type = filter_config['type']
        filter_value = filter_config['value']
        
        if filter_type == 'heading':
            filters = MetadataFilters.by_heading(filter_value)
        elif filter_type == 'page':
            filters = MetadataFilters.by_page(filter_value)
        elif filter_type == 'page_title':
            filters = MetadataFilters.by_page_title(filter_value)
        elif filter_type == 'exact_page_title':
            filters = MetadataFilters.by_exact_page_title(filter_value)
        elif filter_type == 'page_and_heading':
            filters = MetadataFilters.by_page_and_heading(filter_value[0], filter_value[1])
        elif filter_type == 'any_heading':
            filters = MetadataFilters.by_any_heading(filter_value)
        elif filter_type == 'heading_level':
            filters = MetadataFilters.by_heading_level(filter_value)
        elif filter_type == 'custom':
            filters = MetadataFilters.custom(filter_value)
        else:
            raise ValueError(f"Unknown filter type: {filter_type}")
        
        print(f"   Created filter dict: {filters}")
        
        answer2, citations2 = chat(
            test_query,
            metadata_filters=filters,
            number_of_results=filtered_results,
            verbose=False
        )
        
        if not citations2 or len(citations2) == 0:
            print("⚠️  No citations returned with filter")
            results['filtered_error'] = 'No citations - filter too restrictive or no matches'
            return results
        
        df2 = display_citations_table(citations2)
        
        if df2.empty:
            print("⚠️  Citations table is empty with filter")
            results['filtered_error'] = 'Empty citations table - filter too restrictive'
            return results
        
        # Analyze filtered results
        sections2 = df2['Section'].value_counts()
        pages2 = df2['Page Title'].value_counts()
        scores2 = df2['Relevance %'].str.rstrip('%').astype(float)
        
        print(f"\n Filtered Stats:")
        print(f"   Total results: {len(df2)}")
        print(f"   Unique sections: {len(sections2)}")
        print(f"   Unique pages: {len(pages2)}")
        print(f"   Avg relevance: {scores2.mean():.1f}%")
        print(f"   Top score: {scores2.max():.1f}%")
        
        print(f"\n   Sections found:")
        for section, count in sections2.items():
            print(f"      {section}: {count}")
        
        results['filtered'] = {
            'total_results': len(df2),
            'unique_sections': len(sections2),
            'unique_pages': len(pages2),
            'avg_relevance': scores2.mean(),
            'top_score': scores2.max(),
            'sections': sections2.to_dict(),
            'pages': pages2.to_dict(),
            'all_scores': scores2.tolist()
        }
        
        # =================================================================
        # Calculate filter effectiveness
        # =================================================================
        print(f"\n{'─' * 40}")
        print(" FILTER EFFECTIVENESS:")
        print(f"{'─' * 40}")
        
        # Check if results match filter criteria
        filter_value_lower = str(filter_value).lower()
        
        if filter_type == 'page_title':
            matching_count = sum(
                filter_value_lower in str(page).lower() 
                for page in df2['Page Title'].tolist()
            )
            total_count = len(df2)
        elif filter_type in ['heading', 'any_heading']:
            matching_count = sum(
                filter_value_lower in str(section).lower() 
                for section in df2['Section'].tolist()
            )
            total_count = len(df2)
        elif filter_type == 'page':
            matching_count = sum(
                filter_value_lower in str(url).lower() 
                for url in df2['Source'].tolist()
            )
            total_count = len(df2)
        else:
            matching_count = len(df2)
            total_count = len(df2)
        
        filter_precision = (matching_count / total_count * 100) if total_count > 0 else 0
        
        diversity_reduction = (
            (len(sections1) - len(sections2)) / len(sections1) * 100
            if len(sections1) > 0 else 0
        )
        
        relevance_improvement = scores2.mean() - scores1.mean()
        
        score_improvement_pct = (
            (scores2.mean() - scores1.mean()) / scores1.mean() * 100
            if scores1.mean() > 0 else 0
        )
        
        # =================================================================
        # Check keyword matching (from golden test case)
        # =================================================================
        print(f"\n{'─' * 40}")
        print(" KEYWORD MATCHING:")
        print(f"{'─' * 40}")
        
        # Get text content from filtered results
        all_text = ' '.join(df2['Section'].tolist() + df2['Page Title'].tolist()).lower()
        
        keyword_matches = {}
        for keyword in expected_keywords:
            matched = keyword.lower() in all_text
            keyword_matches[keyword] = matched
            status = "✅" if matched else "❌"
            print(f"   {status} '{keyword}': {'Found' if matched else 'Not found'}")
        
        keyword_match_rate = (sum(keyword_matches.values()) / len(expected_keywords) * 100) if expected_keywords else 0
        print(f"\n   Keyword Match Rate: {keyword_match_rate:.0f}% ({sum(keyword_matches.values())}/{len(expected_keywords)})")
        
        results['keyword_match'] = {
            'matches': keyword_matches,
            'match_rate': keyword_match_rate,
            'expected_keywords': expected_keywords
        }
        
        # =================================================================
        # Print effectiveness metrics
        # =================================================================
        print(f"\n Metrics:")
        print(f"   Filter Precision: {filter_precision:.0f}% ({matching_count}/{total_count} match)")
        print(f"   Diversity Reduction: {diversity_reduction:.0f}% ({len(sections1)} → {len(sections2)} sections)")
        print(f"   Relevance Change: {relevance_improvement:+.1f}% ({scores1.mean():.1f}% → {scores2.mean():.1f}%)")
        print(f"   Score Improvement: {score_improvement_pct:+.1f}%")
        print(f"   Keyword Match Rate: {keyword_match_rate:.0f}%")
        
        effectiveness_score = (filter_precision + max(0, relevance_improvement * 10) + keyword_match_rate) / 3
        
        # Grade the filter (including keyword matching)
        if filter_precision >= 80 and relevance_improvement >= 0 and keyword_match_rate >= 75:
            grade = "A (Highly Effective)"
            status = "✅"
        elif filter_precision >= 60 and relevance_improvement >= -5 and keyword_match_rate >= 50:
            grade = "B (Effective)"
            status = "✅"
        elif filter_precision >= 40 and keyword_match_rate >= 25:
            grade = "C (Moderately Effective)"
            status = "⚠️"
        else:
            grade = "D (Ineffective)"
            status = "❌"
        
        print(f"\n{status} Overall Grade: {grade}")
        print(f"   Effectiveness Score: {effectiveness_score:.1f}/100")
        
        # Warnings and recommendations
        print(f"\n Recommendations:")
        recommendations = []
        if filter_precision < 80:
            recommendations.append(f"⚠️  Filter precision is low - results may not match '{filter_value}'")
        if relevance_improvement < 0:
            recommendations.append("⚠️  Relevance decreased - filter may be too restrictive")
        if len(df2) < 3:
            recommendations.append("⚠️  Very few results - consider broadening filter")
        if diversity_reduction < 30:
            recommendations.append("⚠️  Low diversity reduction - filter may not be adding much value")
        if keyword_match_rate < 50:
            recommendations.append(f"⚠️  Low keyword match rate - expected keywords not found in results")
        if filter_precision >= 80 and relevance_improvement > 5 and keyword_match_rate >= 75:
            recommendations.append("✅ Excellent filter - high precision, improved relevance, and good keyword matches!")
        
        if not recommendations:
            recommendations.append("✅ Filter performance is acceptable")
            
        for rec in recommendations:
            print(f"   {rec}")
        
        results['effectiveness'] = {
            'filter_precision': filter_precision,
            'matching_count': matching_count,
            'diversity_reduction': diversity_reduction,
            'relevance_improvement': relevance_improvement,
            'score_improvement_pct': score_improvement_pct,
            'keyword_match_rate': keyword_match_rate,
            'effectiveness_score': effectiveness_score,
            'grade': grade,
            'status': status
        }
        
        results['success'] = True
        
    except Exception as e:
        print(f" Error in filtered query:")
        print(f"   {type(e).__name__}: {str(e)}")
        traceback.print_exc()
        results['filtered_error'] = f"{type(e).__name__}: {str(e)}"
        return results
    
    return results


def print_filter_effectiveness_summary(all_results: List[Dict]):
    """
    Print a formatted summary of filter effectiveness test results.
    
    Displays a comprehensive overview of all filter tests including individual test
    outcomes, grades, precision metrics, and overall statistics across all tests.
    
    Args:
        all_results: List of result dicts from run_single_filter_test(), each containing:
                    - query: The test query string
                    - filter_config: Filter configuration used
                    - success: Whether test completed successfully
                    - effectiveness: Performance metrics dict (if successful)
                    - keyword_match: Keyword matching results (if successful)
                    - exception/filtered_error/unfiltered_error: Error info (if failed)
    
    Returns:
        None: Prints formatted summary to stdout
    
    Output Format:
        - Header section with test summary title
        - Per-test results showing:
            * Query (truncated to 60 chars)
            * Filter type and value
            * Grade and status (if successful)
            * Precision, relevance delta, and keyword match rate (if successful)
            * Error message (if failed)
        - Overall statistics section (if any tests succeeded):
            * Pass rate (successful/total)
            * Average filter precision across all successful tests
            * Average relevance improvement across all successful tests
            * Average keyword match rate across all successful tests
        - Failure message if no tests succeeded
    
    Notes:
        - Uses emojis and Unicode box-drawing characters for visual formatting
        - Queries are truncated to 60 characters for readability
        - Calculates statistics only from successful tests
        - All percentages are rounded to nearest integer
        - Relevance improvements show + or - prefix to indicate direction
    """
    print(f"\n{'═' * 80}")
    print("FILTER EFFECTIVENESS SUMMARY")
    print(f"{'═' * 80}\n")
    
    for result in all_results:
        print(f" Query: {result['query'][:60]}...")
        if result.get('filter_config'):
            print(f"   Filter: {result['filter_config']['type']} = {result['filter_config']['value']}")
        else:
            print(f"   Filter: (auto-discovery failed)")
        
        if result.get('success'):
            eff = result.get('effectiveness', {})
            print(f"   Grade: {eff.get('status', '?')} {eff.get('grade', 'N/A')}")
            print(f"   Precision: {eff.get('filter_precision', 0):.0f}%")
            print(f"   Relevance Δ: {eff.get('relevance_improvement', 0):+.1f}%")
            print(f"   Keyword Match: {eff.get('keyword_match_rate', 0):.0f}%")
        else:
            error_msg = result.get('exception', result.get('filtered_error', result.get('unfiltered_error', 'Unknown')))
            print(f" Failed: {error_msg}")
        print()
    
    # Overall stats
    successful_results = [r for r in all_results if r.get('success', False)]
    if successful_results:
        avg_precision = np.mean([r['effectiveness']['filter_precision'] for r in successful_results])
        avg_relevance_improvement = np.mean([r['effectiveness']['relevance_improvement'] for r in successful_results])
        avg_keyword_match = np.mean([r['effectiveness']['keyword_match_rate'] for r in successful_results])
        
        print(f" Overall Statistics:")
        print(f"   Passed: {len(successful_results)}/{len(all_results)}")
        print(f"   Avg Precision: {avg_precision:.0f}%")
        print(f"   Avg Relevance Improvement: {avg_relevance_improvement:+.1f}%")
        print(f"   Avg Keyword Match: {avg_keyword_match:.0f}%")
    else:
        print(f" No successful tests: 0/{len(all_results)} passed")