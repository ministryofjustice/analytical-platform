"""
Pytest Configuration & Fixtures

This file contains ONLY fixture definitions and pytest hooks.
All mock data is imported from fixtures/mock_data.py
"""

# ============================================================================
# Imports and Path Setup
# ============================================================================

# tests/conftest.py
import sys
import json
import time
import contextlib
from unittest.mock import MagicMock
from typing import Dict, Any

# Add project root to Python path
from pathlib import Path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# -----------------------------------------------------------------------------
# Config import (fallback to test defaults if not present)
# -----------------------------------------------------------------------------
# Only import config if it exists (optional)
try:
    from config import KB_ID, MODEL_ID, REGION
except ImportError:
    # Fallback defaults if config doesn't exist
    KB_ID = "test-kb-123"
    MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"
    REGION = "us-east-1"
    print("⚠️  Config not found, using test defaults")


# -----------------------------------------------------------------------------
# Import production classes (mirror your app's imports)
# -----------------------------------------------------------------------------
import pytest
from helpers.apug.rag.query_analyser_07_01 import QueryAnalyser
from helpers.apug.rag.retrieval_planner_07_02 import RetrievalPlanner
from helpers.apug.rag.filter_generator_07_03 import FilterGenerator
from helpers.apug.rag.ask_smart_07_04 import AskSmart, SmartAnswer


# -----------------------------------------------------------------------------
# Import mock data & helpers from fixtures
# -----------------------------------------------------------------------------
from .fixtures.mock_data import (
    MOCK_KB_CATALOG,
    MOCK_ANALYSES,
    MOCK_DOCUMENTS,
    MOCK_LLM_ANSWERS,
    get_mock_scenario,
    get_test_query_by_id,
    TEST_QUERIES
)

# ============================================================================
# PYTEST CONFIGURATION /PYTEST HOOKS (single definitions)
# ============================================================================

def pytest_configure(config):
    """Configure pytest with custom markers."""
    config.addinivalue_line("markers", "unit: Unit tests (fully mocked, fast)")
    config.addinivalue_line("markers", "smoke: Smoke tests (quick sanity checks)")
    config.addinivalue_line("markers", "integration: Integration tests (detailed validation)")
    config.addinivalue_line("markers", "e2e: End-to-end tests with real AWS (expensive)")
    config.addinivalue_line("markers", "slow: Slow tests")


def pytest_addoption(parser):
    """Add custom command-line options."""
    parser.addoption(
        "--run-e2e",
        action="store_true",
        default=False,
        help="Run E2E tests (makes real AWS API calls)"
    )


def pytest_collection_modifyitems(config, items):
    """Automatically mark tests based on location."""
    for item in items:
        p = str(item.fspath)
        # Auto-mark based on directory
        if "smoke" in p:
            item.add_marker(pytest.mark.smoke)
        elif "integration" in p:
            item.add_marker(pytest.mark.integration)
        elif "e2e" in p or "end2end" in p:
            item.add_marker(pytest.mark.e2e)
            item.add_marker(pytest.mark.slow)


# ============================================================================
# FIXTURES: TEST DATA ACCESS
# ============================================================================

@pytest.fixture(scope="session")
def all_test_queries():
    """Provide all test queries from test_queries.json."""
    return TEST_QUERIES["test_scenarios"]

@pytest.fixture
def get_query(all_test_queries):
    """
    Helper to get query by ID from test_queries.json
    """
    def _get(query_id: str):
        for q in all_test_queries:
            if q["id"] == query_id:
                return q
        pytest.fail(f"Query {query_id} not found in test_queries.json")
    return _get

@pytest.fixture(scope="session")
def kb_catalog():
    """Provide mock KB catalog for tests."""
    return MOCK_KB_CATALOG

# ============================================================================
# FIXTURES: MOCK COMPONENTS
# ============================================================================

@pytest.fixture
def mock_analyser(monkeypatch):
    """
    Mock QueryAnalyser.analyse() to return deterministic QueryAnalysis
    based on keyword routing to mock scenarios (no Bedrock calls).
    """
    
    def mock_analyse(self, query: str, verbose: bool = False):
        scenario = get_mock_scenario(query)
        analysis = MOCK_ANALYSES[scenario]
        
        if verbose:
            print(f"[MOCK] QueryAnalyser routed to: {scenario}")
            print(f"[MOCK] Strategy: {analysis.strategy}, Tools: {analysis.tools_mentioned}")
        
        return analysis
    
    monkeypatch.setattr(QueryAnalyser, "analyse", mock_analyse)

@pytest.fixture
def mock_filter_generator(monkeypatch):
    
    """
    Monkeypatches `FilterGenerator.generate_and_retrieve()` to avoid real Knowledge Base (KB)
    calls and return deterministic `RetrievalResult` objects based on simple keyword
    matching in the input query.

    Purpose:
        - Prevents tests from hitting AWS Bedrock Agent Runtime.
        - Makes end-to-end and component tests fast, stable, and reproducible.
        - Allows you to simulate retrieval outcomes (docs/strategy/fallback) per scenario.

    How it works:
        - Converts the incoming query to lowercase and performs keyword checks:
            * Q1_data_uploader  → if query mentions "data uploader" AND "delete"
                                  returns 2 mock docs, strategy="hybrid", fallback_step=1
            * Q2_rstudio_error  → if query mentions "rstudio" AND any of "502"/"504"/"gateway"
                                  returns 1 mock doc, strategy="filtered", fallback_step=0
            * Q3_quicksight_usage → if query mentions "quicksight" AND "schema"
                                  returns 1 mock doc, strategy="hybrid", fallback_step=0
            * otherwise         → returns [], strategy="broad", fallback_step=0
        - Uses `MOCK_DOCUMENTS[...]` for the returned `documents` (each with content/metadata/score).
        - Echoes `plan.filters` into `filters_used` for observability.
        - Populates `notes` with a brief retrieval summary.

    Parameters:
        monkeypatch (pytest.MonkeyPatch): Pytest utility used to replace the real
            `FilterGenerator.generate_and_retrieve` method with the mock implementation.

    Returns:
        None (pytest fixture). Registers the patched method so any `FilterGenerator` instance
        created during the test session will use this mock.

    Side effects:
        - All calls to `FilterGenerator.generate_and_retrieve(...)` in tests will return
          a `RetrievalResult` constructed from `MOCK_DOCUMENTS` and the inferred scenario.
        - No network calls or AWS dependencies are invoked.

    Requirements:
        - Ensure `MOCK_DOCUMENTS` is defined as:
            {
              "Q1_data_uploader": [ { "content": "...", "metadata": {...}, "score": 0.xx }, ... ],
              "Q2_rstudio_error": [ ... ],
              "Q3_quicksight_usage": [ ... ],
            }
        - Ensure `RetrievalResult` dataclass matches:
            documents: List[Dict[str, Any]]
            count: int
            strategy_used: str
            filters_used: Dict[str, Any]
            fallback_step: int
            notes: str

    Usage:
        - Declare `mock_filter_generator` in your test function (or in a higher-level fixture like
          `ask_smart_instance`) so retrieval is mocked across the pipeline.

        Example:
            >>> def test_pipeline(ask_smart_instance, mock_filter_generator, mock_analyzer):
            ...     res = ask_smart_instance.ask("How do I delete tables in Data Uploader?")
            ...     assert res.sources
            ...     assert res.retrieval_metadata["strategy"] in {"filtered", "hybrid", "broad"}
            ...     assert "Retrieved" in res.retrieval_metadata["notes"]

    Notes:
        - Keep the keyword rules aligned with your test dataset for clarity.
        - For integration tests, skip/disable this fixture and use the real KB.

    """

    def mock_generate_and_retrieve(
            self, 
            query: str, 
            plan, 
            kb_catalog: Dict, 
            verbose: bool = False
        ):
        from helpers.apug.rag.filter_generator_07_03 import RetrievalResult
        
        scenario = get_mock_scenario(query)
        docs = MOCK_DOCUMENTS.get(scenario, [])
        
        # Determine strategy from scenario
        analysis = MOCK_ANALYSES[scenario]
        strategy = analysis.strategy
        
        # Set fallback step based on scenario
        fallback_step = 1 if scenario == "Q1_data_uploader" else 0

        if verbose:
            print(f"[MOCK] FilterGenerator retrieved {len(docs)} docs for: {scenario}")
            print(f"[MOCK] Strategy: {strategy}, Fallback step: {fallback_step}")
        
        return RetrievalResult(
            documents=docs,
            count=len(docs),
            strategy_used=strategy,
            filters_used=getattr(plan, "filters", {}),
            fallback_step=fallback_step,
            notes=f"Retrieved {len(docs)} documents using {strategy} strategy"
        )

    monkeypatch.setattr(
        FilterGenerator, 
        "generate_and_retrieve", 
        mock_generate_and_retrieve
    )

# -------------------------------------------------------------
# 7) Mock Bedrock Runtime (answer generation) content blocks
# -------------------------------------------------------------
@pytest.fixture
def mock_bedrock_llm(monkeypatch):
    
    """
        Monkeypatches the Bedrock Runtime client (`boto3.client("bedrock-runtime")`)
        so that tests do NOT make real LLM calls. Instead, it returns deterministic,
        Anthropic‑style content blocks that match the format expected by
        `AskSmart._generate_answer()`.

        Purpose:
            - Prevent actual AWS Bedrock charges during tests.
            - Ensure answer generation is stable, reproducible, and isolated.
            - Provide realistic, Anthropic-compatible model responses using the
            predefined `MOCK_LLM_ANSWERS`.

        How it works:
            1. Intercepts calls to `boto3.client("bedrock-runtime")`.
            2. Returns a lightweight `MockRuntime` object instead of a real client.
            3. `MockRuntime.invoke_model(...)`:
                - Parses the request body (`messages[*].content[*].text`)
                - Extracts the query text from the content blocks
                - Matches keywords to determine which scenario to return
                - Looks up a canned answer in `MOCK_LLM_ANSWERS`
                - Wraps it in Anthropic’s expected content-block format:
                    {
                        "content": [{"type": "text", "text": "..."}],
                        "usage": { "input_tokens": ..., "output_tokens": ... }
                    }
                - Returns a dict with `"body"` containing a `.read()` method
                (to mimic the real Bedrock streaming response object)

            4. If a different service name (e.g., "bedrock-agent-runtime") is requested,
            the fixture returns a harmless mock client with a dummy `.retrieve()` method
            to prevent accidental AttributeErrors.

        Returned mock response format:
            {
                "body": MockBody({
                    "content": [
                        {"type": "text", "text": "<mock answer text>"}
                    ],
                    "usage": {
                        "input_tokens": 100,
                        "output_tokens": 150
                    }
                })
            }

        Parameters:
            monkeypatch (pytest.MonkeyPatch):
                Pytest utility used to override the global `boto3.client` factory.

        Usage:
            - Add this fixture to your test or to the `ask_smart_instance` fixture.
            - Any call to `AskSmart._generate_answer()` will automatically use the mock.
            - Ensures end-to-end tests can run without network access.

        Notes:
            - This fixture must be applied BEFORE constructing `AskSmart`, because
            AskSmart creates the Bedrock Runtime client in its constructor.
            - Matches the exact Anthropic Bedrock response schema so the rest of the
            pipeline (confidence scoring, validation, answer extraction) behaves
            identically to real usage.
        """

    def make_runtime_client(service_name=None, region_name=None, **kwargs):
        #print(f"[MOCK] boto3.client called with service: {service_name}")

        # Mock bedrock-agent-runtime for KB retrieval
        if service_name == "bedrock-agent-runtime":
            class MockKBClient:
                def retrieve(self, **kwargs):
                    return {"retrievalResults": []}
            return MockKBClient()
        
        if service_name != "bedrock-runtime":
            # Return a benign mock for other services to avoid AttributeError if called.
            client = MagicMock()
            client.retrieve = MagicMock(return_value={"retrievalResults": []})
            return client

        class MockBody:
            def __init__(self, payload):
                self._payload = payload
            def read(self): 
                return json.dumps(self._payload).encode("utf-8")

        class MockRuntime:
            """Simulates boto3 Bedrock Runtime client."""

            def invoke_model(self, modelId: str, body: str) -> Dict[str, Any]:
                print(f"[MOCK] invoke_model called") 
                """
                Simulate model invocation with realistic responses.
                
                Args:
                    modelId: Model ID (ignored in mock)
                    body: JSON string containing the request
                    
                Returns:
                    Dict with 'body' key containing MockBody instance
                """

                req = json.loads(body)
                content = req.get("messages", [{}])[0].get("content", [])

                # Extract user's text from content blocks
                if isinstance(content, list) and content and isinstance(content[0], dict):
                    text = content[0].get("text", "")
                else:
                    text = content if isinstance(content, str) else ""

                # Route to appropriate mock answer
                scenario = get_mock_scenario(text)
                print(f"[MOCK] Routed to scenario: {scenario}")
                answer, _ = MOCK_LLM_ANSWERS.get(
                    scenario, 
                    MOCK_LLM_ANSWERS["FALLBACK"]
                )
                print(f"[MOCK] Returning answer: {answer[:50]}...")

                # Estimate tokens (rough approximation: 1 token ≈ 4 chars)
                input_tokens = max(len(text) // 4, 50)
                output_tokens = max(len(answer) // 4, 20)
                
                payload = {
                    "content": [{"type": "text", "text": answer}],
                    "usage": {
                        "input_tokens": input_tokens, 
                        "output_tokens": output_tokens
                        },
                        "stop_reason": "end_turn",
                        "model": modelId
                }
                return {"body": MockBody(payload)}

        return MockRuntime()

    monkeypatch.setattr("boto3.client", make_runtime_client)

# ============================================================================
# INSTANCE FIXTURES
# ============================================================================

# ------------------------------------------------
# 8) Build AskSmart wired to the above mocks
# ------------------------------------------------
@pytest.fixture
def ask_smart_instance(
    mock_analyser,
    mock_filter_generator, 
    mock_bedrock_llm, 
    kb_catalog
):
    """
    Return a fully-wired AskSmart instance with all mocks applied.
    
    This fixture provides an end-to-end testable AskSmart pipeline where:
    - QueryAnalyser uses mock analysis
    - FilterGenerator uses mock retrieval
    - Bedrock LLM uses mock answers
    
    Perfect for integration tests without external dependencies.
    
    """
    analyser = QueryAnalyser()
    planner = RetrievalPlanner(min_results=3)
    filter_gen = FilterGenerator(
        kb_id=KB_ID,
        region=REGION,
        llm_model_id=MODEL_ID
    )
    return AskSmart(
        analyser=analyser,
        planner=planner,
        filter_gen=filter_gen,
        kb_id=KB_ID,
        kb_catalog=kb_catalog,
        answer_model_id=MODEL_ID,
        region=REGION
    )

@pytest.fixture
def real_ask_smart_instance(request,kb_catalog):
    """
    Return a real AskSmart instance WITHOUT mocks.
    
    Use this fixture for integration tests that need to verify
    actual behavior against real AWS services.
    
    Mark tests using this fixture with @pytest.mark.integration
    """

    if not request.config.getoption("--run-e2e"):
        pytest.skip("Use --run-e2e to enable E2E tests (real AWS calls).")

    analyser = QueryAnalyser(model_id=MODEL_ID, region=REGION)
    planner = RetrievalPlanner(min_results=3)
    filter_gen = FilterGenerator(
        kb_id=KB_ID,
        region=REGION,
        llm_model_id=MODEL_ID
    )
    
    return AskSmart(
        analyser=analyser,
        planner=planner,
        filter_gen=filter_gen,
        kb_id=KB_ID,
        kb_catalog=kb_catalog,
        answer_model_id=MODEL_ID,
        region=REGION
    )

@pytest.fixture
def capture_pipeline_metrics():
    """
    Lightweight timing helper for tests. Use to capture rough durations for
    analysis/retrieval/generation/total. Not for strict performance assertions.
    """
    metrics = {
        "analysis_time_ms": None,
        "retrieval_time_ms": None,
        "generation_time_ms": None,
        "total_time_ms": None,
        "notes": {}
    }

    @contextlib.contextmanager
    def timer(field: str):
        start = time.perf_counter()
        try:
            yield
        finally:
            elapsed_ms = (time.perf_counter() - start) * 1000.0
            metrics[field] = elapsed_ms

    def note(key: str, value):
        metrics["notes"][key] = value

    return metrics, timer, note


# ============================================================================
# VALIDATION
# ============================================================================

def validate_mock_data():
    """Validate that all mock data references are consistent."""
    errors = []
    
    # Load test queries
    test_scenarios = TEST_QUERIES.get("test_scenarios", [])
    scenario_ids = {s["id"] for s in test_scenarios}
    
    # Get tool mapping - create case-insensitive lookup
    tool_mapping = MOCK_KB_CATALOG["metadata"]["tool_mapping"]
    
    # Create normalized tool lookup (case-insensitive, handles variations)
    normalized_tools = {}
    for tool_key in tool_mapping.keys():
        # Store both original and lowercase/normalized versions
        normalized_tools[tool_key.lower()] = tool_key
        normalized_tools[tool_key] = tool_key
        
        # Add common variations
        if "amazon" in tool_key.lower():
            # "Amazon Athena" -> "athena"
            short_name = tool_key.lower().replace("amazon", "").strip()
            normalized_tools[short_name] = tool_key
    
    # Check that all test query IDs have corresponding mock data
    for scenario_id in scenario_ids:
        # Skip edge cases from having mock documents
        if scenario_id in ["Q4_ambiguous", "Q5_empty", "Q6_gibberish"]:
            continue
            
        if scenario_id not in MOCK_ANALYSES:
            errors.append(
                f"Test scenario '{scenario_id}' has no corresponding entry in MOCK_ANALYSES"
            )
        
        if scenario_id not in MOCK_DOCUMENTS:
            errors.append(
                f"Test scenario '{scenario_id}' has no corresponding entry in MOCK_DOCUMENTS"
            )
        
        if scenario_id not in MOCK_LLM_ANSWERS:
            errors.append(
                f"Test scenario '{scenario_id}' has no corresponding entry in MOCK_LLM_ANSWERS"
            )
    
    # Check that all MOCK_ANALYSES have corresponding documents and answers
    for scenario_id in MOCK_ANALYSES.keys():
        if scenario_id not in ["Q4_ambiguous", "Q5_empty", "Q6_gibberish"]:
            if scenario_id not in MOCK_DOCUMENTS:
                errors.append(
                    f"Mock analysis '{scenario_id}' has no corresponding MOCK_DOCUMENTS"
                )
            
            if scenario_id not in MOCK_LLM_ANSWERS:
                errors.append(
                    f"Mock analysis '{scenario_id}' has no corresponding MOCK_LLM_ANSWERS"
                )
    
    # Verify all tools mentioned in analyses exist in KB catalog (normalized check)
    for scenario_id, analysis in MOCK_ANALYSES.items():
        for tool in analysis.tools_mentioned:
            tool_normalized = tool.lower()
            
            # Check if tool exists in normalized lookup
            if tool_normalized not in normalized_tools and tool not in normalized_tools:
                errors.append(
                    f"Tool '{tool}' mentioned in scenario '{scenario_id}' "
                    f"but not in MOCK_KB_CATALOG tool_mapping. "
                    f"Available tools: {list(tool_mapping.keys())}"
                )
    
    # Validate test query expected behaviors
    for scenario in test_scenarios:
        scenario_id = scenario["id"]
        expected = scenario.get("expected_behavior", {})
        
        # Check if min_sources matches what we have in MOCK_DOCUMENTS
        if "min_sources" in expected:
            min_sources = expected["min_sources"]
            actual_docs = len(MOCK_DOCUMENTS.get(scenario_id, []))
            
            # Allow edge cases to have 0 documents
            if scenario_id not in ["Q4_ambiguous", "Q5_empty", "Q6_gibberish"]:
                if actual_docs < min_sources:
                    errors.append(
                        f"Scenario '{scenario_id}' expects min_sources={min_sources} "
                        f"but MOCK_DOCUMENTS only has {actual_docs} documents"
                    )
    
    if errors:
        raise ValueError(
            "Mock data validation failed:\n" + 
            "\n".join(f"  - {e}" for e in errors)
        )

# Run validation when module loads
try:
    validate_mock_data()
    print("✅ Mock data validation passed")
except ValueError as e:
    print(f"⚠️  {e}")
    # Don't fail import, just warn

# ============================================================================
# E2E FIXTURES (Real AWS Services)
# ============================================================================

@pytest.fixture(scope="class")
def query_analyser_instance():
    """Fixture providing real QueryAnalyser instance for E2E tests."""
    analyser = QueryAnalyser(
        region=REGION,
        model_id=MODEL_ID
    )
    return analyser


@pytest.fixture(scope="class")
def retrieval_planner_instance():
    """Fixture providing real RetrievalPlanner instance for E2E tests."""
    planner = RetrievalPlanner(min_results=3)
    return planner


@pytest.fixture(scope="class")
def filter_generator_instance():
    """Fixture providing real FilterGenerator instance for E2E tests."""
    filter_gen = FilterGenerator(
        kb_id=KB_ID,
        region=REGION,
        llm_model_id=MODEL_ID
    )
    return filter_gen


@pytest.fixture(scope="class")
def kb_retriever_instance():
    """Fixture providing real KnowledgeBaseRetriever instance for E2E tests."""
    from helpers.apug.rag.ask_smart_07_04 import KnowledgeBaseRetriever
    
    retriever = KnowledgeBaseRetriever(
        kb_id=KB_ID,
        region=REGION
    )
    return retriever


"""

def test_pipeline_timings(ask_smart_instance, capture_pipeline_metrics):
    metrics, timer, note = capture_pipeline_metrics()

    # If your AskSmart exposes timing hooks you can wrap them.
    # Otherwise, time the whole call or sections around it:
    with timer("total_time_ms"):
        res = ask_smart_instance.ask("How do I delete tables in Data Uploader?")

    # Optional: add notes you care about
    note("strategy", res.retrieval_metadata.get("strategy"))
    note("docs_retrieved", res.retrieval_metadata.get("docs_retrieved"))

    # Soft checks / logging (avoid brittle strict assertions)
    assert metrics["total_time_ms"] is not None
    # You can print when running locally
    print(f"[TIMING] total={metrics['total_time_ms']:.1f}ms | notes={metrics['notes']}")


"""
# End of tests/conftest.py


# ============================================================================
# LAMBDA & API GATEWAY FIXTURES (Add to existing conftest.py)
# ============================================================================

@pytest.fixture
def mock_lambda_logger():
    """Mock SmartRAGLogger for Lambda/Flask tests"""
    from unittest.mock import Mock
    
    logger = Mock()
    logger.request_id = 'test-req-123'
    logger.log_component = Mock()
    logger.log_error = Mock()
    logger.log_success = Mock()
    logger.finalize = Mock()
    return logger


@pytest.fixture
def api_gateway_authorizer_event():
    """
    Valid API Gateway Lambda Authorizer event (v2.0 format)
    Used for testing lambda_authorizer.py
    """
    def _create_event(
        token: str = "test-token-123",
        method_arn: str = "arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/POST/ask"
    ):
        return {
            "version": "2.0",
            "type": "REQUEST",
            "routeArn": method_arn,
            "identitySource": [f"Bearer {token}"] if token else [],
            "routeKey": "POST /ask",
            "rawPath": "/ask",
            "headers": {
                "authorization": f"Bearer {token}" if token else "",
                "content-type": "application/json"
            },
            "requestContext": {
                "accountId": "123456789012",
                "apiId": "abcdef123",
                "http": {
                    "method": "POST",
                    "path": "/ask",
                    "sourceIp": "203.0.113.1"
                }
            }
        }
    return _create_event


@pytest.fixture
def api_gateway_lambda_event():
    """
    Valid API Gateway event for main Lambda (POST /ask)
    Used for testing lambda_handler.py
    """
    def _create_event(
        query: str = "What is RAG?",
        authorizer_context: dict = None
    ):
        event = {
            "version": "2.0",
            "routeKey": "POST /ask",
            "rawPath": "/ask",
            "headers": {
                "content-type": "application/json",
                "authorization": "Bearer test-token-123"
            },
            "requestContext": {
                "http": {
                    "method": "POST",
                    "path": "/ask",
                    "sourceIp": "203.0.113.1"
                }
            },
            "body": json.dumps({"text": query}),
            "isBase64Encoded": False
        }
        
        if authorizer_context:
            event["requestContext"]["authorizer"] = authorizer_context
        
        return event
    return _create_event


@pytest.fixture
def mock_process_query_success(mock_lambda_logger):
    """Mock successful process_query for Lambda/Flask tests"""
    def _mock_result(query: str = "What is RAG?"):
        return {
            'answer': f'Mock answer for: {query}',
            'confidence': 0.92,
            'sources': [
                {'title': 'Doc 1', 'score': 0.95, 'url': 'https://example.com/doc1'},
                {'title': 'Doc 2', 'score': 0.88, 'url': 'https://example.com/doc2'}
            ],
            'request_id': mock_lambda_logger.request_id,
            'validation_issues': []
        }
    return _mock_result


# ============================================================================
# FLASK APP FIXTURES (Add to existing conftest.py)
# ============================================================================

@pytest.fixture
def flask_client():
    """Flask test client with TESTING mode enabled"""
    from app import app
    app.config['TESTING'] = True
    
    with app.test_client() as client:
        yield client


@pytest.fixture
def flask_auth_token(monkeypatch):
    """Set AUTH_TOKEN for Flask tests"""
    monkeypatch.setenv('AUTH_TOKEN', 'test-token-123')
    
    # Also patch the imported AUTH_TOKEN in app.py
    import app
    monkeypatch.setattr(app, 'AUTH_TOKEN', 'test-token-123')


# ============================================================================
# STREAMLIT CLIENT FIXTURES (Add to existing conftest.py)
# ============================================================================

@pytest.fixture
def streamlit_api_client():
    """Create RAGAPIClient instance for testing"""
    from helpers.streamline.api_client import RAGAPIClient
    
    return RAGAPIClient(
        api_url="https://api.example.com",
        auth_token="test-token-123"
    )


@pytest.fixture
def mock_requests_response():
    """Factory for creating mock requests.Response objects"""
    from unittest.mock import Mock
    
    def _create_response(
        status_code: int = 200,
        json_data: dict = None,
        raise_for_status: bool = False
    ):
        mock_response = Mock()
        mock_response.status_code = status_code
        mock_response.json.return_value = json_data or {}
        
        if raise_for_status:
            import requests
            mock_response.raise_for_status.side_effect = requests.HTTPError()
        else:
            mock_response.raise_for_status.return_value = None
        
        return mock_response
    
    return _create_response


# ============================================================================
# PYTEST MARKERS UPDATE (Add to existing pytest_configure)
# ============================================================================

def pytest_configure(config):
    """Configure pytest with custom markers."""
    # Your existing markers
    config.addinivalue_line("markers", "unit: Unit tests (fully mocked, fast)")
    config.addinivalue_line("markers", "smoke: Smoke tests (quick sanity checks)")
    config.addinivalue_line("markers", "integration: Integration tests (detailed validation)")
    config.addinivalue_line("markers", "e2e: End-to-end tests with real AWS (expensive)")
    config.addinivalue_line("markers", "slow: Slow tests")
    
    # NEW: Add markers for Lambda/Flask/Streamlit tests
    config.addinivalue_line("markers", "lambda_handler: Lambda handler integration tests")
    config.addinivalue_line("markers", "flask_api: Flask REST API tests")
    config.addinivalue_line("markers", "streamlit_client: Streamlit client tests")
    config.addinivalue_line("markers", "api_gateway: API Gateway integration tests")
