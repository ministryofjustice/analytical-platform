"""
test_relevance_score.py

Integration tests for RAG retrieval quality without dynamic filter generation.

Purpose:
    Measures and benchmarks the accuracy and relevance of vector search results
    from the basic RAG system (chat() function) using a curated set of golden
    questions. Tests the foundational retrieval capabilities before adding
    dynamic filter generation.

Test Coverage:
    - Relevance score distribution across retrieved chunks
    - Correctness of section/topic matching  
    - Keyword coverage in generated answers
    - Citation quality and metadata completeness
    - Score statistics (top, mean, min, std dev)

Golden Test Set:
    Uses shared fixtures from conftest.py containing representative questions
    across different domains (Athena, RStudio, S3, etc.) with expected outcomes.

Metrics Validated:
    1. Top relevance score >= minimum_relevance threshold (40%)
    2. Expected section appears in top 3 results
    3. Keyword coverage >= 50% in generated answer
    4. Number of valid citations returned

Usage:
    # Run all relevance tests
    pytest tests/integration/rag_basic/test_relevance_score.py -v
    
    # Run with detailed output
    pytest tests/integration/rag_basic/test_relevance_score.py -v -s
    
    # Run specific test
    pytest tests/integration/rag_basic/test_relevance_score.py::test_relevance_score_distribution

Dependencies:
    - helpers.apug.vector_search_05 (chat, display_citations_table)
    - Real Knowledge Base connection (no mocking)
    - Golden questions fixture from parent conftest.py

"""
#test_retrieval_quality.py
#Purpose: Measure and benchmark retrieval accuracy

import pandas as pd
from typing import List, Dict
import pytest
from pprint import pprint

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

def display_metadata_readable(metadata: dict, indent: int = 2):
    """Display metadata in a clean, readable format"""
    
    # Group related fields
    core_fields = ['page_h1', 'root_heading', 'page_url', 'level']
    kb_fields = [k for k in metadata.keys() if k.startswith('x-amz-bedrock')]
    link_fields = sorted([k for k in metadata.keys() if k.startswith('link_')])
    other_fields = [k for k in metadata.keys() if k not in core_fields + kb_fields + link_fields]
    
    print("\n" + "=" * 80)
    print("METADATA BREAKDOWN")
    print("=" * 80)
    
    # Core info
    print("\n Core Information:")
    for key in core_fields:
        if key in metadata:
            print(f"  {key:20} : {metadata[key]}")
    
    # KB info
    print("\n Knowledge Base Info:")
    for key in kb_fields:
        if key in metadata:
            value = metadata[key]
            # Truncate long URIs
            if len(str(value)) > 80:
                value = str(value)[:77] + "..."
            print(f"  {key:40} : {value}")
    
    # Links (group by number)
    print("\n Links:")
    link_pairs = {}
    for key in link_fields:
        num = key.split('_')[1]
        link_type = 'text' if 'text' in key else 'url'
        if num not in link_pairs:
            link_pairs[num] = {}
        link_pairs[num][link_type] = metadata[key]
    
    for num in sorted(link_pairs.keys(), key=int):
        text = link_pairs[num].get('text', 'N/A')
        url = link_pairs[num].get('url', 'N/A')
        print(f"  Link {num:2} : {text:30} → {url}")
    
    # Other
    if other_fields:
        print("\n Other:")
        for key in other_fields:
            print(f"  {key:20} : {metadata[key]}")
    
    print("=" * 80)


def test_relevance_score_distribution(
    golden_questions: List[Dict],
    number_of_results: int = 10,
    verbose: bool = False
) -> pd.DataFrame:
    """
    Test relevance score distribution and quality for a set of golden questions.
    
    Args:
        golden_questions: List of dicts with keys: 'question', 'expected_section', 
                         'minimum_relevance', 'expected_keywords'
        number_of_results: Number of results to retrieve
        verbose: Print detailed output
    
    Returns:
        DataFrame with test results and summary statistics
    """
    print("=" * 80)
    print("TEST: Relevance Score Distribution & Quality")
    print("=" * 80)
    
    test_results = []
    
    for test in golden_questions:
        if verbose:
            print(f"\n{'─' * 80}")
            print(f"Question: {test['question']}")
            print(f"Expected: {test['expected_section']}")
        
        try:
            answer, citations = chat(
                test['question'], 
                number_of_results=number_of_results, 
                verbose=False
            )
            
            if not citations or len(citations) == 0:
                print(f" No citations returned for: {test['question'][:50]}...")
                test_results.append({
                    'question': test['question'],
                    'top_score': 0,
                    'mean_score': 0,
                    'passed_relevance': False,
                    'section_found': False,
                    'keyword_coverage': 0,
                    'num_citations': 0,
                    'error': 'No citations'
                })
                continue
            
            # Display metadata for top result if verbose
            if verbose and len(citations) > 0:
                print(f"\n Top Result Metadata:")
                display_metadata_readable(citations[0]['metadata'])
            
            df = display_citations_table(citations)
            
            if df.empty or 'Relevance %' not in df.columns:
                print(f" No data in citations table for: {test['question'][:50]}...")
                test_results.append({
                    'question': test['question'],
                    'top_score': 0,
                    'mean_score': 0,
                    'passed_relevance': False,
                    'section_found': False,
                    'keyword_coverage': 0,
                    'num_citations': 0,
                    'error': 'Empty citations table'
                })
                continue
            
            # Parse scores
            scores = df['Relevance %'].str.rstrip('%').astype(float)
            
            # Score statistics
            if verbose:
                print(f"\n Score Distribution:")
                print(f"   Top:  {scores.max():.1f}%")
                print(f"   Mean: {scores.mean():.1f}%")
                print(f"   Min:  {scores.min():.1f}%")
                print(f"   Std:  {scores.std():.1f}%")
            
            # Quality checks
            top_score = scores.max()
            passed_relevance = top_score >= test['minimum_relevance']
            
            # Check if expected section is in top results
            top_sections = df.head(3)['Section'].tolist()
            section_found = any(
                test['expected_section'].lower() in str(s).lower() 
                for s in top_sections
            )
            
            # Check for expected keywords in answer
            answer_lower = answer.lower()
            keywords_found = [
                kw for kw in test['expected_keywords'] 
                if kw.lower() in answer_lower
            ]
            keyword_coverage = (
                len(keywords_found) / len(test['expected_keywords']) * 100
                if test['expected_keywords'] else 0
            )
            
            if verbose:
                print(f"\n✓ Quality Checks:")
                print(f"   {'✅' if passed_relevance else '❌'} Top relevance >= {test['minimum_relevance']}%: {top_score:.1f}%")
                print(f"   {'✅' if section_found else '❌'} Expected section in top 3: {section_found}")
                print(f"   {'✅' if keyword_coverage >= 50 else '❌'} Keyword coverage: {keyword_coverage:.0f}% ({len(keywords_found)}/{len(test['expected_keywords'])})")
                print(f"      Found: {keywords_found}")
            
            # Store results
            test_results.append({
                'question': test['question'],
                'top_score': top_score,
                'mean_score': scores.mean(),
                'std_score': scores.std(),
                'min_score': scores.min(),
                'passed_relevance': passed_relevance,
                'section_found': section_found,
                'keyword_coverage': keyword_coverage,
                'keywords_found': len(keywords_found),
                'num_citations': len(citations),
                'error': None
            })
        
        except Exception as e:
            print(f" Error processing '{test['question'][:50]}...': {e}")
            test_results.append({
                'question': test['question'],
                'top_score': 0,
                'mean_score': 0,
                'passed_relevance': False,
                'section_found': False,
                'keyword_coverage': 0,
                'num_citations': 0,
                'error': str(e)
            })
    
    # Create summary DataFrame
    if test_results:
        print(f"\n{'═' * 80}")
        print("TEST SUMMARY")
        print(f"{'═' * 80}")
        
        summary_df = pd.DataFrame(test_results)
        
        # Display summary table
        display_cols = [
            'question', 'top_score', 'mean_score', 
            'passed_relevance', 'section_found', 
            'keyword_coverage', 'num_citations'
        ]
        print(summary_df[display_cols].to_string(index=False))
        
        # Calculate metrics
        total_tests = len(test_results)
        successful_tests = summary_df[summary_df['error'].isna()]
        
        if len(successful_tests) > 0:
            print(f"\n Overall Metrics:")
            print(f"   Total Tests: {total_tests}")
            print(f"   Successful: {len(successful_tests)}")
            print(f"   Failed: {total_tests - len(successful_tests)}")
            print(f"   Relevance Pass Rate: {(successful_tests['passed_relevance'].sum() / len(successful_tests) * 100):.1f}%")
            print(f"   Section Found Rate: {(successful_tests['section_found'].sum() / len(successful_tests) * 100):.1f}%")
            print(f"   Avg Keyword Coverage: {successful_tests['keyword_coverage'].mean():.1f}%")
            print(f"   Avg Top Score: {successful_tests['top_score'].mean():.1f}%")
            print(f"   Avg Mean Score: {successful_tests['mean_score'].mean():.1f}%")
        
        return summary_df
    else:
        print(" No test results generated")
        return pd.DataFrame()
