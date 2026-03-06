### AskSmart RAG Pipeline - Test Suite Documentation

#### Overview

This test suite validates the AskSmart RAG pipeline using a **layered testing approach**: 
Smoke → Integration → End‑to‑End(E2E). 

The goal is to provide:
  - Fast feedback during development
  - High confidence before deployment
  - Safe, optional validation against real AWS Bedrock services

Mock‑based tests deliver ~90% confidence at minimal cost, while E2E tests verify real‑world behavior when explicitly enabled.

## Test Structure

```
tests/
├── fixtures/
│   ├── init.py
│   ├── assertions.py                           # Reusable validation helpers
│   ├── mock_data.py                            # Mock responses and scenarios
│   └── test_queries.json                       # Test scenarios with expected behaviors
│
├── e2e/
│   ├── init.py
│   ├── test_ask_smart_e2e.py                   # Real AWS tests (slow & expensive)
│   │── test_logging_observability_e2e.py
│   │── test_query_analyser_e2e.py
│
├── integration/
│   ├── init.py                             # Full pipeline validation (20–30s)
│   ├── rag_smart/
│   │   ├── init.py
│   │   └── test_ask_smart_integration.py       # RAG pipeline integration tests
│   │
│   ├── rag_with_filter/
│       ├── init.py
│       ├── test_edge_caseerror_handling.py     # Tests error handling edge cases
│       ├── test_metadat_filter_effectiveness.py# Ensures metadata filtering works
│       ├── test_performance_and_latency.py     # Measures latency & bottlenecks
│       ├── test_relavance_score.py             # Validates ranking relevance logic
│       └── test_retrieval_consistency.py       # Ensures stable retrieval results
│
├── smoke/                                      # Quick sanity checks (5–10s)
│   ├── init.py
│   └── test_ask_smart_smoke.py
│
├── unit_tests/                                 # Fast, isolated, fully mocked tests
│   ├── init.py
│   ├── test_integartion_extraction.py          # Unit tests for extraction logic
│   ├── test_run_validation.py                  # Unit tests for validation flow
│   └── test_unit_helpers.py                    # Unit tests for helper methods
│
├── init.py
├── pytest.ini                                   # Pytest configuration
├── helper.py                                    # Generic test utilities
├── conftest.py                                  # Root Pytest fixtures & setup
└── README.md
```
---

### Running Tests

#### By Test Level

```
- pytest -m smoke              # Smoke only
- pytest -m integration        # Integration only
- pytest -m e2e --run-e2e      # E2E only (requires flag)
- pytest -m "not e2e"          # Skip E2E (default)

```

#### Specific E2E Tests
```
# Test full RAG pipeline with real AWS
pytest tests/end2end/test_ask_smart_e2e.py --run-e2e -v

# Test logging/observability pipeline ✨ NEW
pytest tests/end2end/test_e2e_logging_observability.py --run-e2e -v

# Test query analysis component
pytest tests/end2end/test_query_analyser_e2e.py --run-e2e -v

# Run all E2E tests
pytest tests/end2end/ --run-e2e -v
```

#### Specific Tests

```
- pytest tests/smoke/test_smoke.py -v
- pytest tests/integration/test_ask_smart_integration.py::TestAskSmartIntegration -v
- pytest tests/end2end/test_e2e_logging_observability.py --run-e2e -v
- pytest tests/smoke/test_smoke_pipeline.py::TestAskSmartSmoke::test_pipeline_runs_without_error -v
- pytest -k "data_uploader" -v

```

#### Useful Pytest Options

```
1. -v              # Verbose output
2. -s              # Show print statements
3. -x              # Stop on first failure
4. --lf            # Re-run last failures
5. --tb=short      # Shorter tracebacks
6. --durations=10  # Show 10 slowest tests

```
---

Understanding Results
✅ Smoke Pass → Integration Pass → E2E Pass
**Meaning**: Everything works
**Action**: Deploy with confidence

✅ Smoke Pass → ❌ Integration Fail
**Meaning**: Components work but pipeline logic broken
**Check**: 
  - Strategy selection, 
  - tool detection, 
  - Source retrieval &
  - answer quality

Debug:

```

from tests.helpers import print_response_summary
result = ask_smart_instance.ask("test query")
print_response_summary(result, verbose=True)

```

✅ Smoke + Integration Pass → ❌ E2E Fail
Meaning: Mock behavior differs from real AWS
Check:

  - AWS credentials: aws sts get-caller-identity
  - Config: KB_ID, MODEL_ID, REGION in config.py
  - IAM Permissions: 
      - bedrock:InvokeModel, 
      - bedrock:Retrieve
  - KB structure vs mocks

  Run diagnostics: 
  
  ```
  pytest -m e2e --run-e2e -k "debugging" -v
  
  ```

✅ Pipeline Pass → ❌ Logging E2E Fail

Meaning: Lambda or CloudWatch logging issues
Check:

  - Lambda deployed: aws lambda get-function --function-name 
  - CloudWatch log group exists: /aws/lambda/
  - IAM Permissions:
    - logs:CreateLogGroup
    - logs:CreateLogStream
    - logs:PutLogEvents
  - Lambda environment variables set correctly

#### Check Lambda logs manually
aws logs tail /aws/lambda/ --follow

#### Run test with verbose output
pytest tests/end2end/test_e2e_logging_observability.py --run-e2e -v -s

---

### Debugging Failed Tests

#### 1. Verbose output with print statements

```
pytest path/to/test.py::test_name -v -s

```

#### 2. Inspect Responses

```
from tests.helpers import print_response_summary
print_response_summary(result, test_case, verbose=True)

```

#### 3. Check mock routing

```

from tests.fixtures.mock_data import get_mock_scenario
scenario = get_mock_scenario("your query")
print(f"Routes to: {scenario}")

```

#### 4. Validate mock data consistency

```

from tests.fixtures.mock_data import validate_mock_data
validate_mock_data()  # Auto-runs on import

```
---
### Adding New Test Scenarios
#### 1. Add to test_queries.json

```

{
  "id": "Q9_new_scenario",
  "category": "how_to",
  "query": "Your test query",
  "expected_behavior": {
    "min_sources": 1,
    "min_confidence": 0.5,
    "expected_strategy": "filtered"
  }
}

```

### 2. Add Mock Data to mock_data.py

```

# MOCK_ANALYSES
"Q9_new_scenario": QueryAnalysis(...),

# MOCK_DOCUMENTS
"Q9_new_scenario": [{...}],

# MOCK_LLM_ANSWERS
"Q9_new_scenario": ("Answer...", 0.75),

# QUERY_KEYWORD_MAPPING
"Q9_new_scenario": {"keywords": ["key1", "key2"]},

```

3. Add Integration Test 

```

def test_new_scenario(self, ask_smart_instance):
    result = ask_smart_instance.ask("Your query")
    assert_minimum_sources(result, 1)
    assert_confidence_in_range(result, 0.5, 1.0)

```

---

### Test Levels Explained

#### Smoke Tests (tests/smoke/)
**Purpose**: Ensure pipeline doesn’t crash and returns a valid SmartAnswer

  - Fast
  - Minimal assertions
  - Run constantly during development
**What it validates:**

  - Pipeline executes without errors
  - Returns SmartAnswer object
  - Basic fields populated (answer, confidence)

#### Integration Tests (tests/integration/)
**Purpose**: Validate full RAG pipeline with mocks

  - Strategy selection
  - Tool detection
  - Source structure
  - Confidence thresholds
  - Scenario‑driven expectations

✅ Primary quality gate
**What it validates:**

  - Correct strategy chosen for each query type
  - Tools properly detected from query
  - Sources retrieved match expected tools
  - Answer quality meets confidence thresholds
  - Edge cases handled (empty results, ambiguous queries)


#### E2E Tests (tests/end2end/)
**Purpose**: Validate real AWS Bedrock + KB

  - Non‑deterministic
  - Slow & expensive
  - Explicitly enabled
**What it validates:**

RAG Pipeline E2E (test_ask_smart_e2e.py):

  - Real Bedrock model inference
  - Real Knowledge Base retrieval
  - Actual document ranking
  - End-to-end latency
  - Logging/Observability E2E (test_e2e_logging_observability.py)

**Lambda function execution**
  - Request/response cycle
  - CloudWatch log delivery
  - Log structure validation
  - All components logged correctly
  - Conversation record created
  - Request ID tracking
**Query Analysis E2E (test_query_analyser_e2e.py):**

  - Real LLM query understanding
  - Strategy selection accuracy
  - Tool detection precision

### CI/CD Integration

#### .github/workflows/test.yml

```

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.9'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Smoke Tests
        run: pytest -m smoke -v --tb=short

      - name: Integration Tests
        run: pytest -m integration -v --tb=short

      - name: E2E Tests (main only)
        if: github.ref == 'refs/heads/main'
        run: pytest -m e2e --run-e2e -v
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION: eu-west-2

```

---
### FAQ
Q: Why skip E2E by default?
A: Real AWS calls are slow (~2-5min), expensive ($0.10+/run), and non-deterministic. Integration tests provide 90% confidence at 1% cost.

Q: Tests pass locally but fail in CI?
A: Check Python version (3.9+), dependencies installed, and file paths (use Path(__file__).parent).

Q: How to update mocks when real behavior changes?
A: Run E2E test, capture real response, update mock_data.py, re-run integration tests.

Q: Can I run tests in my IDE?
A: Yes. Most IDEs auto-discover pytest. Right-click test file/function → "Run Test".

Q: What does the logging E2E test validate? 
A: It validates the complete observability pipeline:

  - Lambda execution succeeds
  - All pipeline components log with timing
  - Logs appear in CloudWatch within 10 seconds
  - Log structure matches expected schema
  - Conversation record created with correct fields
  - Request ID tracking works end-to-end
Q: How often should I run E2E tests?
A:
 - Smoke + Integration: Every commit (fast, cheap)
 - RAG Pipeline E2E: Before deployment, weekly scheduled runs
 - Logging E2E: After Lambda deployment, when changing logging logic

---


#### Quick Start

```

First Time Setup
# Install test dependencies
pip install pytest pytest-cov

# Validate test framework
pytest --collect-only

# Run smoke tests to verify setup
pytest -m smoke -v
Daily Development Workflow

#### Daily Workflow

# 1. Quick check while coding (5-10s)
pytest -m smoke -v

# 2. Before committing (30s)
pytest -m "smoke or integration" -v

# 3. Before deployment (2-5min, optional)
pytest -m e2e --run-e2e -v

```
#### Specific Workflows

```

# Run specific file
pytest tests/smoke/test_smoke.py -v

# Run specific class
pytest tests/integration/test_integration.py::TestAskSmartIntegration -v

# Run specific test method
pytest tests/smoke/test_smoke.py::TestAskSmartSmoke::test_pipeline_runs_without_error -v

# Run specific parametrized test
pytest "tests/integration/test_integration.py::TestAskSmartIntegration::test_tool_identification[Q1_data_uploader-Data Uploader]" -v

```
