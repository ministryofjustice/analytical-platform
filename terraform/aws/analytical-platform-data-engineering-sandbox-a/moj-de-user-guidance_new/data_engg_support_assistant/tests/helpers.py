"""
Test Helper Functions

Reusable utilities for test validation and debugging.
These are imported by test files as needed.

Usage:
    from tests.helpers import assert_valid_response, print_response_summary
"""

# tests/helpers.py
# tests/helpers.py
from typing import Any, Dict
import re


def print_response_summary(response, test_case=None, verbose=False):
    """
    Print a formatted summary of an AskSmart response.
    Useful for debugging test failures.
    
    Args:
        response: SmartAnswer instance
        test_case: Optional test case dict with expected behavior
        verbose: If True, print full answer text
    """
    print("\n" + "=" * 80)

    if test_case:
        print(f"TEST CASE: {test_case.get('id', 'Unknown')}")
        print(f"CATEGORY: {test_case.get('category', 'Unknown')}")
        query = test_case.get("query", "")
        print(f"QUERY: {query[:100]}{'...' if len(query) > 100 else ''}")
        print("-" * 80)

    print("ANSWER:")
    answer = response.answer or ""
    if verbose:
        print(answer)
    else:
        trimmed = answer[:200] + ("..." if len(answer) > 200 else "")
        print(trimmed)

    print("\nRETRIEVAL METADATA:")
    for k, v in (response.retrieval_metadata or {}).items():
        print(f"  {k}: {v}")

    print(f"\nSOURCES: {len(response.sources)}")
    if verbose and response.sources:
        for i, source in enumerate(response.sources[:3], 1):
            content = source.get("content", "") or ""
            print(f"  Source {i}: {content[:100]}{'...' if len(content) > 100 else ''}")

    if test_case and "expected_behavior" in test_case:
        print("\nEXPECTED BEHAVIOR:")
        for k, v in test_case["expected_behavior"].items():
            print(f"  {k}: {v}")

    print("=" * 80 + "\n")


def compare_responses(response1, response2) -> dict:
    """
    Compare two responses and return differences.
    Useful for testing consistency or comparing mock vs real responses.
    
    Args:
        response1: First SmartAnswer instance
        response2: Second SmartAnswer instance
        
    Returns:
        Dict with comparison results
    """
    comparison = {
        "confidence_diff": abs(response1.confidence - response2.confidence),
        "source_count_diff": abs(len(response1.sources) - len(response2.sources)),
        "strategy_match": (
            response1.retrieval_metadata.get("strategy") == 
            response2.retrieval_metadata.get("strategy")
        ),
        "answer_similarity": _word_overlap_similarity(response1.answer, response2.answer)
    }
    
    return comparison


def _word_overlap_similarity(text1: str, text2: str) -> float:
    """
    Simple word overlap similarity (0.0 to 1.0).
    Uses regex tokenization to avoid punctuation issues.
    """
    words1 = set(re.findall(r"\w+", text1.lower()))
    words2 = set(re.findall(r"\w+", text2.lower()))

    if not words1 and not words2:
        return 1.0  # Both empty = perfect match
    
    if not words1 or not words2:
        return 0.0  # One empty = no match
    
    intersection = words1 & words2
    union = words1 | words2
    
    return len(intersection) / len(union)


def extract_keywords(text: str, min_length: int = 4) -> list:
    """
    Extract keywords from text for validation.
    
    Args:
        text: Text to analyze
        min_length: Minimum word length to consider
        
    Returns:
        List of keywords (lowercase, deduplicated)
    """
    tokens = re.findall(r"\w+", text.lower())
    keywords = [t for t in tokens if len(t) >= min_length and t.isalpha()]
    seen, result = set(), []
    for kw in keywords:
        if kw not in seen:
            seen.add(kw)
            result.append(kw)
    return result


def assert_contains_any(text: str, keywords: list, case_sensitive: bool = False):
    """
    Assert that text contains at least one of the keywords.
    
    Args:
        text: Text to search
        keywords: List of keywords to look for
        case_sensitive: Whether to match case
        
    Raises:
        AssertionError: If no keywords found
    """
    if not case_sensitive:
        text = text.lower()
        keywords = [k.lower() for k in keywords]
    
    found = [k for k in keywords if k in text]
    
    assert found, f"Text should contain at least one of {keywords}, but found none"


def assert_confidence_in_range(response, min_conf: float, max_conf: float):
    """
    Assert confidence is within expected range.
    
    Args:
        response: SmartAnswer instance
        min_conf: Minimum acceptable confidence (0.0-1.0)
        max_conf: Maximum acceptable confidence (0.0-1.0)
        
    Raises:
        AssertionError: If confidence outside range
    """
    conf = response.confidence
    assert min_conf <= conf <= max_conf, \
        f"Confidence {conf:.2%} outside expected range [{min_conf:.2%}, {max_conf:.2%}]"