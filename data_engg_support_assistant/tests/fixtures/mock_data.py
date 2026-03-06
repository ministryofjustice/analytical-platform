"""
Mock Data for AskSmart Pipeline Tests

Central repository for all test data:
- Mock KB catalogs
- Mock query analyses
- Mock retrieved documents
- Mock LLM answers

This separation allows:
1. Easy updates to test scenarios
2. Reusability across test files
3. Clear data structures
4. Documentation of expected formats
"""

# ============================================================================
# Imports and Path Setup
# ============================================================================

# tests/conftest.py
import os,json
from typing import Dict, Any, List
from pathlib import Path

# Import the QueryAnalysis dataclass
from helpers.apug.rag.query_analyser_07_01 import QueryAnalysis

# ============================================================================
# LOAD TEST QUERIES FROM JSON
# ============================================================================

def load_test_queries() -> Dict[str, Any]:
    """Load test queries from JSON file."""
    test_queries_path = Path(__file__).parent /"test_queries.json"

    if not test_queries_path.exists():
        raise FileNotFoundError(f"test_queries.json not found at {test_queries_path}")

    with open(test_queries_path, "r") as f:
        return json.load(f)

TEST_QUERIES = load_test_queries()

# ============================================================================
# MOCK KB CATALOG
# ============================================================================
"""
    Represents the structure of the knowledge base catalog.
    Used by: RetrievalPlanner, FilterGenerator
    """
MOCK_KB_CATALOG: Dict[str, Any] = {
   
    "page_h1_list": [
        "Data Uploader - Analytical Platform User Guidance",
        "Amazon Athena - Analytical Platform User Guidance",
        "Airflow - Analytical Platform User Guidance",
        "RStudio - Analytical Platform User Guidance",
        "QuickSight - Analytical Platform User Guidance",
        "Git and GitHub",
        "Infrastructure - Analytical Platform User Guidance",
        "Acceptable Use Policy - Analytical Platform User Guidance",
    ],
    "root_headings": [
        "Getting started",
        "Prerequisites",
        "Troubleshooting",
        "Data management",
        "Accessing the console",
        "Common errors",
        "Best practices",
        "Deployment",
        "GitHub",
        "CI/CD",
        "Security",
        "Configuration",
        "Usage",
        "Working with tables",
        "Uploader flowchart",
    ],
    "metadata": {
        "tool_mapping": {
            "Data Uploader": {
                "page_h1_candidates": ["Data Uploader - Analytical Platform User Guidance"]
                },
            "Amazon Athena": {
                "page_h1_candidates": ["Amazon Athena - Analytical Platform User Guidance"]
                },
            "RStudio": {
                "page_h1_candidates": ["RStudio - Analytical Platform User Guidance"]
                },
            "QuickSight": {
                "page_h1_candidates": ["QuickSight - Analytical Platform User Guidance"]
                },
            "Airflow": {
                    "page_h1_candidates": ["Airflow - Analytical Platform User Guidance"]
                },
            "GitHub": {
                "page_h1_candidates": ["Git and GitHub"]
                },
            "Infrastructure": {
                "page_h1_candidates": ["Infrastructure - Analytical Platform User Guidance"]
                },
            "Athena": {
                "page_h1_candidates": ["Amazon Athena - Analytical Platform User Guidance"]
            },
            "data-uploader": {
                "page_h1_candidates": ["Data Uploader - Analytical Platform User Guidance"]
            },
        }
    }
}

# ---------------------------------------------------------
# 2) MOCK QUERY ANALYSES (QueryAnalyzer output)
# ---------------------------------------------------------
MOCK_ANALYSES: Dict[str, QueryAnalysis] = {
    "Q1_data_uploader": QueryAnalysis(
        intent_primary={"primary": "find_table_deletion_process", "type": "how-to"},
        complexity_level="medium",
        strategy="hybrid",
        confidence_score=0.85,
        suggested_filters={
            "page_h1": {"in": [
                "Data Uploader - Analytical Platform User Guidance",
                "Athena - Analytical Platform User Guidance"
            ]},
            "root_heading": {"in": ["Data management", "Getting started"]}
        },
        top_k=10,
        tools_mentioned=["Data Uploader", "Amazon Athena"],
        raw_analysis={"intent": {"type": "how-to"}}
    ),
    "Q2_rstudio_error": QueryAnalysis(
        intent_primary={"primary": "rstudio_gateway_errors", "type": "troubleshooting"},
        complexity_level="low",
        strategy="filtered",
        confidence_score=0.88,
        suggested_filters={
            "page_h1": {"equals": "RStudio - Analytical Platform User Guidance"},
            "root_heading": {"equals": "Troubleshooting"}
        },
        top_k=8,
        tools_mentioned=["RStudio"],
        raw_analysis={"intent": {"type": "troubleshooting"}}
    ),
    "Q3_quicksight_schema": QueryAnalysis(
        intent_primary={"primary": "quicksight_schema_refresh", "type": "how-to"},
        complexity_level="medium",
        strategy="filtered",
        confidence_score=0.78,
        suggested_filters={
            "page_h1": {"in": [
                "QuickSight - Analytical Platform User Guidance",
                "Athena - Analytical Platform User Guidance"
            ]},
            "root_heading": {"in": ["Usage", "Working with tables"]}
        },
        top_k=12,
        tools_mentioned=["Amazon Athena","QuickSight"],
        raw_analysis={"intent": {"type": "how-to"}}
    ),
    "Q4_ambiguous": QueryAnalysis(
        intent_primary={"primary": "unspecified", "type": "exploratory"},
        complexity_level="high",
        strategy="broad",
        confidence_score=0.32,
        suggested_filters={"page_h1": None, "root_heading": None},
        top_k=18,
        tools_mentioned=[],
        raw_analysis={"intent": {"type": "exploratory"}}
    ),
     "Q5_empty": QueryAnalysis(
        intent_primary={"primary": "invalid_input", "type": "exploratory"},
        complexity_level="low",
        strategy="broad",
        confidence_score=0.0,
        suggested_filters={"page_h1": None, "root_heading": None},
        top_k=0,
        tools_mentioned=[],
        raw_analysis={}
    ),
    "Q6_gibberish": QueryAnalysis(
        intent_primary={"primary": "unclear_intent", "type": "exploratory"},
        complexity_level="high",
        strategy="broad",
        confidence_score=0.15,
        suggested_filters={"page_h1": None, "root_heading": None},
        top_k=20,
        tools_mentioned=[],
        raw_analysis={}
    ),
    "Q7_policy": QueryAnalysis(
        intent_primary={"primary": "s3_bucket_configuration", "type": "documentation"},
        complexity_level="medium",
        strategy="filtered",
        confidence_score=0.72,
        suggested_filters={
            "page_h1": {"equals": "Infrastructure - Analytical Platform User Guidance"},
            "root_heading": {"equals": "Best Practices"}
        },
        top_k=10,
        tools_mentioned=["Infrastructure"],
        raw_analysis={"intent": {"type": "documentation"}}
    ),
    
    "Q8_airflow": QueryAnalysis(
        intent_primary={"primary": "airflow_deployment_issue", "type": "troubleshooting"},
        complexity_level="high",
        strategy="hybrid",
        confidence_score=0.75,
        suggested_filters={
            "page_h1": {"in": [
                "Airflow - Analytical Platform User Guidance",
                "Git and GitHub"
            ]},
            "root_heading": {"in": ["Deployment", "CI/CD"]}
        },
        top_k=12,
        tools_mentioned=["Airflow", "GitHub"],
        raw_analysis={"intent": {"type": "troubleshooting"}}
    ),
}

# ---------------------------------------------------------
# 3) MOCK RETRIEVED DOCUMENTS (FilterGenerator output) 
# ---------------------------------------------------------
# Content to be updated based on the query context
"""
MOCK_DOCUMENTS simulates Knowledge Base (KB) retrieval results for tests.

Key (str): scenario id (e.g., "Q1_data_uploader")
Value (List[Dict]): KB doc hits; each has:
  - "content": short text snippet (represents a KB section)
  - "metadata": {
        "page_h1": exact page title,
        "root_heading": section within that page
    }
  - "score": float relevance score
"""
MOCK_DOCUMENTS: Dict[str, List[Dict[str, Any]]] = {
    "Q1_data_uploader": [
        {
            "content": "Working with tables: You can DROP TABLE in SQL ...",
            "metadata": {
                "page_h1": "Amazon Athena - Analytical Platform User Guidance", 
                "root_heading": "Working with tables"
                },
            "score": 0.82
        },

        {
            "content": "Uploader flowchart: Data stored in S3 ...",
            "metadata": {
                "page_h1": "Data Uploader - Analytical Platform User Guidance", 
                "root_heading": "Uploader flowchart"
            },
            "score": 0.74
        },
    ],
    "Q2_rstudio_error": [
        {
            "content": "Troubleshooting: 502/504 Gateway errors may occur due to ...",
            "metadata": {
                "page_h1": "RStudio - Analytical Platform User Guidance", 
                "root_heading": "Troubleshooting"
            },
            "score": 0.66
        }
    ],
    "Q3_quicksight_schema": [
        {
            "content": "QuickSight datasets: Refresh schema with SPICE/non‑SPICE options ...",
            "metadata": {
                "page_h1": "QuickSight - Analytical Platform User Guidance", 
                "root_heading": "Usage"
            },
            "score": 0.63
        }
    ],
    "Q7_policy": [
        {
            "content": "Infrastructure best practices: configure S3 buckets following least privilege and lifecycle policies...",
            "metadata": {
                "page_h1": "Infrastructure - Analytical Platform User Guidance",
                "root_heading": "Best Practices",
            },
            "score": 0.59
        }
    ],
    "Q8_airflow": [
        {
            "content": "Airflow DAG deployment process and CI/CD integration...",
            "metadata": {
                "page_h1": "Airflow - Analytical Platform User Guidance",
                "root_heading": "Deployment",
            },
            "score": 0.58
        },
        {
            "content": "GitHub Actions workflow configuration for deployments...",
            "metadata": {
                "page_h1": "Git and GitHub",
                "root_heading": "CI/CD",
            },
            
            "score": 0.55
        }
    ],
}

# -----------------------------------------
# 4) MOCK LLM ANSWERS (answer generation output)
# -----------------------------------------
# Format: (answer_text, confidence_score)
# Content to be updated based on the query context and retrieved documents. This helps not calling LLM in tests. If we call LLMit may break the tests if the model output changes.

MOCK_LLM_ANSWERS: Dict[str, tuple] = {
    "Q1_data_uploader": (
        "To delete obsolete tables, you can use the DROP TABLE command in Athena. "
        "If the table was created via Data Uploader, coordinate with data owners to "
        "remove the table and update any ingestion processes where needed. The data "
        "itself will remain in S3 unless explicitly deleted. [Doc 1][Doc 2]",
        0.86
    ),
    
    "Q2_rstudio_error": (
        "For 502/504 Gateway errors in RStudio, retry after a short interval (a few minutes) "
        "and check the service status page. These errors typically occur during service restarts "
        "or network timeouts. Contact platform support if the issue persists. [Doc 1]",
        0.84
    ),
    
    "Q3_quicksight_schema": (
        "To use QuickSight, first create datasets by connecting to your Athena tables. "
        "Then build analyses and publish dashboards. You can configure dataset connections "
        "with SPICE (in-memory) or direct query mode in the Usage section. Set up refresh "
        "schedules as needed for your data. [Doc 1]",
        0.78
    ),

    "Q4_ambiguous": (
        "I need more specific information to help you. Could you please provide details about:\n"
        "- Which tool or service you're using\n"
        "- What error message you're seeing\n"
        "- What you were trying to do\n"
        "This will help me give you a more accurate answer.",
        0.32
    ),
    
    "Q7_policy": (
        "Follow infrastructure best practices for S3: implement least-privilege IAM policies, "
        "configure lifecycle rules for data retention, enable versioning and encryption, and "
        "use bucket policies to control access. [Doc 1]",
        0.72
    ),
    
    "Q8_airflow": (
        "Resolve Airflow deployment issues by ensuring all CI/CD checks pass and your DAGs "
        "are properly committed to the repository. Check that your DAG files are in the correct "
        "directory (dags/) and pass syntax validation. Review the deployment logs for specific "
        "error messages. [Doc 1][Doc 2]",
        0.75
    ),
    
    "FALLBACK": (
        "I need more information to help you effectively. "
        "Please provide specific details about your issue.",
        0.20
    )
}


# ============================================================================
# 5) QUERY KEYWORD MAPPING (for mock routing)
# ============================================================================
# Used by mock_analyser and mock_filter_generator to route queries to correct mock data

QUERY_KEYWORD_MAPPING = {
    "Q1_data_uploader": {
        "keywords": ["data uploader", "delete", "table"], 
        },
    "Q2_rstudio_error": {
        "keywords": ["rstudio", "502", "504", "gateway"], 
        },
    "Q3_quicksight_schema": {
        "keywords": ["quicksight", "schema","athena", "dataset"], 
        },
    "Q4_ambiguous": {
        "keywords": ["not working", "help"],
        },  # Fallback
    "Q5_empty": {
        "keywords": [], 
    },  # Empty query
    "Q6_gibberish": {
        "keywords": [], 
    },  # Gibberish query
   "Q7_policy": {
        "keywords": ["s3", "bucket", "policy", "infrastructure"],
    },
    "Q8_airflow": {
        "keywords": ["airflow", "deployment", "github", "ci/cd"],

    },
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def get_mock_scenario(query: str) -> str:
    """
    Route a query string to the appropriate mock scenario.

    How it works:
        - Converts the incoming query to lowercase and performs keyword checks.
        - Returns a scenario ID from MOCK_ANALYSES based on keyword matching.
    Args:
        query: User query string
        
    Returns:
        str: Key from MOCK_ANALYSES (Q1_data_uploader, Q2_rstudio_error, etc.)
    """
    ql = (query or "").strip().lower()

    if not ql:
        return "Q5_empty"
    
    # Check for specific ambiguous phrases first
    if ("not working" in ql or "it's not working" in ql or "help" in ql) and len(ql.split()) < 10:
        return "Q4_ambiguous"
    
    # Check for gibberish (very short queries with no meaningful words)
    words = ql.split()
    if len(words) <= 3:
        # If all words are very short or non-alphabetic, likely gibberish
        meaningful_words = [w for w in words if len(w) >= 3 and w.isalpha()]
        if not meaningful_words:
            return "Q6_gibberish"

    # Score each scenario based on keyword matches
    best_match = None
    best_score = 0

    # Check each scenario in order
    for scenario_id, mapping in QUERY_KEYWORD_MAPPING.items():
        if scenario_id in ["Q4_ambiguous", "Q5_empty", "Q6_gibberish"]:
            continue  # Skip fallbacks for now
        
        keywords = mapping.get("keywords", [])
        if not keywords:
            continue
        
        # Count how many keywords match
        matches = sum(1 for kw in keywords if kw in ql)
        
        if matches > best_score:
            best_score = matches
            best_match = scenario_id
    
    # Return best match if we found any keywords
    if best_match and best_score > 0:
        return best_match
    
    # Fallback
    return "Q4_ambiguous"

def get_test_query_by_id(query_id: str) -> Dict[str, Any]:
    """
    Get a test query by ID from the loaded test_queries.json.
    
    Args:
        query_id: Query ID (e.g., "Q1", "Q2")
        
    Returns:
        Dict containing the query and expected behavior
    """
    for scenario in TEST_QUERIES["test_scenarios"]:
        if scenario["id"] == query_id:
            return scenario
    
    raise ValueError(f"Query ID {query_id} not found in test_queries.json")

def get_all_test_scenarios() -> List[Dict[str, Any]]:
    """
    Get all test scenarios from test_queries.json.
    
    Returns:
        List of test scenario dictionaries
    """
    return TEST_QUERIES["test_scenarios"]


def get_scenarios_by_category(category: str) -> List[Dict[str, Any]]:
    """
    Get all test scenarios of a specific category.
    
    Args:
        category: Category name (e.g., "troubleshooting_error", "how_to_multi_part")
        
    Returns:
        List of test scenarios matching the category
    """
    return [
        scenario for scenario in TEST_QUERIES["test_scenarios"]
        if scenario.get("category") == category
    ]
