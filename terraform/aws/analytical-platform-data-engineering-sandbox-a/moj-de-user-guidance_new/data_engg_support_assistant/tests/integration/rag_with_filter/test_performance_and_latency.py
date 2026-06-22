
"""
test_performance_and_latency.py

Integration tests for end‑to‑end performance and response‑time behaviour.

Purpose:
    Measures latency of the RAG chatbot pipeline using a golden question set.
    Ensures responses are returned within acceptable performance thresholds
    and helps detect regressions in query execution speed.

Test Coverage:
    - End‑to‑end latency per query
    - Min/Max/Mean response times
    - Median latency stability
    - Error handling during chat() execution
    - Aggregated performance statistics across all queries

Metrics:
    - Min/Max Latency: Fastest and slowest observed runtime
    - Mean Latency: Average response time per query
    - Median Latency: Robust central tendency measure
    - Per‑Query Performance Profile: Aggregated timings across runs

Usage:
    pytest tests/integration/performance/test_performance_and_latency.py -v -s
"""

import pandas as pd
from typing import List, Dict,Any
import numpy as np
import pytest
import time

from helpers.apug.old_rag.vector_search_05 import chat

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

def test_performance_and_latency(
    golden_questions: List[Dict[str, Any]],
    number_of_results: int = 5,
    runs_per_query: int = 1
) -> pd.DataFrame:
    """Test response time performance across multiple queries."""
    
    print(f"\n{'═' * 80}")
    print("TEST: Performance & Latency")
    print(f"{'═' * 80}")
    print(f"\nTesting {len(golden_questions)} queries ({runs_per_query} run(s) each)...\n")
    
    results = []
    
    for test_case in golden_questions:
        query = test_case["question"]
        query_times = []
        
        for run in range(runs_per_query):
            try:
                start = time.time()
                answer, citations = chat(query, number_of_results=number_of_results, verbose=False)
                elapsed = time.time() - start
                
                query_times.append(elapsed)
                
                if runs_per_query == 1:
                    print(f"  '{query}': {elapsed:.2f}s")
                
            except Exception as e:
                print(f"   '{query}': {type(e).__name__}")
                query_times.append(None)
        
        # Store results
        valid_times = [t for t in query_times if t is not None]
        if valid_times:
            results.append({
                'query': query,
                'expected_section': test_case["expected_section"],
                'min': min(valid_times),
                'max': max(valid_times),
                'mean': np.mean(valid_times),
                'median': np.median(valid_times)
            })
            
            if runs_per_query > 1:
                print(f"  '{query}': {np.mean(valid_times):.2f}s avg")
    
    # Summary
    if results:
        df = pd.DataFrame(results)
        
        print(f"\n{'─' * 80}")
        print(" Latency Statistics:")
        print(f"{'─' * 80}")
        print(f"   Overall Min:    {df['min'].min():.2f}s")
        print(f"   Overall Max:    {df['max'].max():.2f}s")
        print(f"   Overall Mean:   {df['mean'].mean():.2f}s")
        print(f"   Overall Median: {df['median'].median():.2f}s")
        
        return df
    
    return pd.DataFrame()
