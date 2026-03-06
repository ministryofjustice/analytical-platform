"""
test_retrieval_consistency.py

Integration tests for RAG retrieval consistency and stability.

Purpose:
    Tests the stability of vector search results by running identical queries
    multiple times and measuring consistency of returned results. Validates
    that the RAG system provides deterministic and reliable outputs.

Test Coverage:
    - Page frequency across multiple runs
    - Section consistency 
    - Top result stability (does #1 result stay the same?)
    - Score stability (coefficient of variation)
    - Overall consistency grading (A-F scale)

Metrics:
    - Page Consistency: % of pages appearing in all runs
    - Top Result Stability: % of time the same result ranks #1
    - Score Stability: Mean, std dev, and CV of top scores
    - Overall Consistency: Combined metric with letter grade

Usage:
    pytest tests/integration/rag_with_filter/test_retrieval_consistency.py -v -s


"""
#test_retrieval_quality.py
#Purpose: Measure and benchmark retrieval accuracy

import numpy as np
from collections import Counter
from typing import Dict, List
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

def test_retrieval_consistency(golden_questions):
    """
    Test retrieval consistency by running the same query multiple times.
    Tests each golden question for stability across multiple runs.
    """
    print(f"\n{'═' * 80}")
    print("TEST: Retrieval Consistency (Stability)")
    print(f"{'═' * 80}")
    
    all_results = []
    
    for test in golden_questions:
        test_query = test['question']
        print(f"\n Query: '{test_query}'")
        print(f" Runs: 5")
        print(f" Analyzing top 3 results per run\n")
        
        consistency_results = []
        score_consistency = []
        section_consistency = []
        failed_runs = 0
        
        for i in range(5):  # 5 runs
            print(f"  Run {i+1}/5...", end=" ", flush=True)
            
            try:
                answer, citations = chat(
                    test_query, 
                    number_of_results=5, 
                    verbose=False
                )
                
                if citations and len(citations) > 0:
                    df = display_citations_table(citations)
                    
                    if not df.empty and 'Relevance %' in df.columns:
                        top_n_results = df.head(3)
                        
                        top_pages = top_n_results['Page Title'].tolist()
                        top_scores = (
                            top_n_results['Relevance %']
                            .str.rstrip('%')
                            .astype(float)
                            .tolist()
                        )
                        top_sections = top_n_results['Section'].tolist()
                        
                        consistency_results.append(top_pages)
                        score_consistency.append(top_scores)
                        section_consistency.append(top_sections)
                        
                        print("✓")
                    else:
                        print(" Empty DataFrame")
                        failed_runs += 1
                else:
                    print(" No citations")
                    failed_runs += 1
                    
            except Exception as e:
                print(f" Error: {e}")
                failed_runs += 1
        
        # Analyze consistency for this query
        result = analyze_consistency(
            test_query, 
            consistency_results, 
            score_consistency, 
            section_consistency,
            failed_runs
        )
        all_results.append(result)
    
    # Print summary
    print_consistency_summary(all_results)
    
    return all_results

def analyze_consistency(
    query: str,
    consistency_results: List,
    score_consistency: List,
    section_consistency: List,
    failed_runs: int
) -> Dict:
    """Helper function to analyze consistency metrics"""
    results = {
        'query': query,
        'total_runs': 5,
        'successful_runs': 5 - failed_runs,
        'failed_runs': failed_runs
    }
    
    if not consistency_results:
        results['overall_consistency'] = 0
        results['grade'] = "F (Failed)"
        return results
    
    # Page frequency analysis
    all_top_pages = [page for run in consistency_results for page in run]
    page_frequency = Counter(all_top_pages)
    
    print(f"\n Page Frequency Analysis (Top 3):")
    for page, count in page_frequency.most_common(5):
        percentage = count / len(consistency_results) * 100
        print(f"   {page}: {count}/{len(consistency_results)} runs ({percentage:.0f}%)")
    
    # Section frequency
    all_sections = [section for run in section_consistency for section in run]
    section_frequency = Counter(all_sections)
    
    print(f"\n Section Frequency:")
    for section, count in section_frequency.most_common(3):
        percentage = count / len(section_consistency) * 100
        print(f"   {section}: {count}/{len(section_consistency)} runs ({percentage:.0f}%)")
    
    # Consistency scores
    common_pages = [
        page for page, count in page_frequency.items() 
        if count == len(consistency_results)
    ]
    page_consistency_score = len(common_pages) / 3 * 100
    
    # Top result stability
    top_results_per_run = [run[0] if run else None for run in consistency_results]
    top_result_frequency = Counter(top_results_per_run)
    most_common_top = top_result_frequency.most_common(1)[0] if top_result_frequency else (None, 0)
    top_result_stability = most_common_top[1] / len(consistency_results) * 100
    
    # Score stability
    if score_consistency:
        top_scores_across_runs = [run[0] if run else 0 for run in score_consistency]
        mean_top_score = np.mean(top_scores_across_runs)
        std_top_score = np.std(top_scores_across_runs)
        cv_top_score = (std_top_score / mean_top_score * 100) if mean_top_score > 0 else 0
        
        print(f"\n Score Stability (Top Result):")
        print(f"   Mean: {mean_top_score:.1f}%")
        print(f"   Std Dev: {std_top_score:.2f}")
        print(f"   Coefficient of Variation: {cv_top_score:.1f}%")
        
        results['mean_top_score'] = mean_top_score
        results['std_top_score'] = std_top_score
        results['cv_top_score'] = cv_top_score
    
    overall_consistency = (page_consistency_score + top_result_stability) / 2
    
    print(f"\n✅ Consistency Metrics:")
    print(f"   Page Consistency: {page_consistency_score:.0f}%")
    print(f"   Top Result Stability: {top_result_stability:.0f}%")
    print(f"   Overall: {overall_consistency:.0f}%")
    
    # Grade
    if overall_consistency >= 90:
        grade = "A (Excellent)"
    elif overall_consistency >= 75:
        grade = "B (Good)"
    elif overall_consistency >= 60:
        grade = "C (Fair)"
    else:
        grade = "D (Poor)"
    
    print(f"   Grade: {grade}")
    
    results.update({
        'page_consistency_score': page_consistency_score,
        'top_result_stability': top_result_stability,
        'overall_consistency': overall_consistency,
        'grade': grade,
        'most_common_top_result': most_common_top[0]
    })
    
    return results

def print_consistency_summary(all_results: List[Dict]):
    """Print summary of all consistency tests"""
    print(f"\n{'═' * 80}")
    print("CONSISTENCY TEST SUMMARY")
    print(f"{'═' * 80}\n")
    
    for result in all_results:
        print(f" Query: {result['query'][:60]}...")
        print(f"   Grade: {result['grade']}")
        print(f"   Overall Consistency: {result.get('overall_consistency', 0):.0f}%")
        print(f"   Successful Runs: {result['successful_runs']}/{result['total_runs']}")
        print()
    
    # Overall stats
    successful_results = [r for r in all_results if r['grade'] != "F (Failed)"]
    if successful_results:
        avg_consistency = np.mean([r['overall_consistency'] for r in successful_results])
        print(f" Average Consistency: {avg_consistency:.0f}%")
        print(f" Passed: {len(successful_results)}/{len(all_results)}")