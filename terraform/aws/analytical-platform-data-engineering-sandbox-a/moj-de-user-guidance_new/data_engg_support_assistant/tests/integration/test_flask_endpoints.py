"""
Test Flask REST API endpoints
Ensures Flask and Lambda behave consistently
"""
import pytest
import json
from unittest.mock import patch, Mock

# Import Flask app
from app import app

# Import fixtures
from tests.fixtures.mock_responses import (
    mock_successful_query_result,
    mock_bedrock_throttling_error,
    mock_bedrock_service_error
)
from tests.test_helpers import create_mock_logger


@pytest.fixture
def client():
    """Flask test client"""
    app.config['TESTING'] = True
    return app.test_client()


class TestFlaskHealthEndpoint:
    """Test /health endpoint"""
    
    @patch('app.ask_smart_pipeline', Mock())
    def test_health_returns_200_when_pipeline_initialized(self, client):
        """✅ Pipeline initialized → 200 healthy"""
        response = client.get('/health')
        
        assert response.status_code == 200
        data = response.get_json()
        
        assert data['status'] == 'healthy'
        assert data['pipeline'] == 'initialized'
        assert 'model' in data
        assert 'region' in data
        assert 'kb_id' in data
        assert 'timestamp' in data
    
    @patch('app.ask_smart_pipeline', None)
    def test_health_returns_503_when_pipeline_failed(self, client):
        """❌ Pipeline failed → 503 unhealthy"""
        response = client.get('/health')
        
        assert response.status_code == 503
        data = response.get_json()
        
        assert data['status'] == 'unhealthy'
        assert data['pipeline'] == 'failed'
        assert 'Pipeline initialization failed' in data['message']
    
    def test_health_does_not_require_auth(self, client):
        """✅ Health endpoint accessible without authentication"""
        # No Authorization header
        response = client.get('/health')
        
        # Should not return 401
        assert response.status_code in [200, 503]  # Either healthy or unhealthy


class TestFlaskAskEndpoint:
    """Test /ask endpoint"""
    
    # ==================== SUCCESSFUL REQUESTS ====================
    
    @patch('app.AUTH_TOKEN', 'test-token-123')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_returns_200_with_valid_token_and_query(self, mock_process, mock_logger_class, client):
        """✅ Valid token + query → 200 with answer"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        response = client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer test-token-123'}
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        assert data['success'] is True
        assert 'answer' in data['data']
        assert 'confidence' in data['data']
        assert 'sources' in data['data']
        assert 'request_id' in data['data']
        
        # Verify logger was finalized
        mock_logger.finalize.assert_called_once()
    
    @patch('app.AUTH_TOKEN', 'secret-key')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_handles_bearer_case_insensitive(self, mock_process, mock_logger_class, client):
        """✅ 'bearer' (lowercase) should work"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        response = client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'bearer secret-key'}  # lowercase
        )
        
        assert response.status_code == 200
    
    # ==================== AUTHENTICATION ERRORS ====================
    
    @patch('app.AUTH_TOKEN', 'correct-token')
    def test_ask_returns_401_with_missing_auth_header(self, client):
        """❌ Missing Authorization header → 401"""
        
        response = client.post('/ask', json={'text': 'What is Flask?'})
        
        assert response.status_code == 401
        data = response.get_json()
        
        assert data['error'] == 'Unauthorized'
        assert 'Invalid or missing Bearer token' in data['message']
    
    @patch('app.AUTH_TOKEN', 'correct-token')
    def test_ask_returns_401_with_wrong_token(self, client):
        """❌ Wrong token → 401"""
        
        response = client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer wrong-token'}
        )
        
        assert response.status_code == 401
    
    @patch('app.AUTH_TOKEN', 'correct-token')
    def test_ask_returns_401_with_malformed_auth_header(self, client):
        """❌ Malformed Authorization header → 401"""
        
        # Wrong format (not "Bearer ")
        response = client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Basic abc123'}
        )
        
        assert response.status_code == 401
    
    # ==================== INPUT VALIDATION ERRORS ====================
    
    @patch('app.AUTH_TOKEN', 'test-token')
    def test_ask_returns_400_with_missing_body(self, client):
        """❌ Missing request body → 400"""
        
        response = client.post(
            '/ask',
            headers={'Authorization': 'Bearer test-token'}
        )
        
        assert response.status_code == 400
        data = response.get_json()
        assert 'Request body must be JSON' in data['message']
    
    @patch('app.AUTH_TOKEN', 'test-token')
    def test_ask_returns_400_with_invalid_json(self, client):
        """❌ Invalid JSON → 400"""
        
        response = client.post(
            '/ask',
            data='not valid json',
            headers={
                'Authorization': 'Bearer test-token',
                'Content-Type': 'application/json'
            }
        )
        
        assert response.status_code == 400
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_returns_400_with_empty_query(self, mock_process, mock_logger_class, client):
        """❌ Empty query → 400"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = ValueError("Empty query provided")
        
        response = client.post(
            '/ask',
            json={'text': ''},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        assert response.status_code == 400
        data = response.get_json()
        assert data['error'] == 'Bad Request'
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('app.SmartRAGLogger')
    def test_ask_returns_400_with_missing_text_field(self, mock_logger_class, client):
        """❌ Missing 'text' field → 400"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        
        response = client.post(
            '/ask',
            json={'query': 'Wrong field name'},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        assert response.status_code == 400
    
    # ==================== BEDROCK ERRORS ====================
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_returns_429_on_bedrock_throttling(self, mock_process, mock_logger_class, client):
        """❌ Bedrock throttling → 429 with Retry-After"""
        from helpers.apug.rag.query_processor import BedrockThrottlingError
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        
        error = BedrockThrottlingError("Rate exceeded", retry_after=8)
        mock_process.side_effect = error
        
        response = client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        assert response.status_code == 429
        assert response.headers['Retry-After'] == '8'
        
        data = response.get_json()
        assert data['error'] == 'Too Many Requests'
        assert data['retry_after_seconds'] == 8
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_returns_503_on_bedrock_service_error(self, mock_process, mock_logger_class, client):
        """❌ Bedrock service error → 503"""
        from helpers.apug.rag.query_processor import BedrockServiceError
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = BedrockServiceError("Service down")
        
        response = client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        assert response.status_code == 503
        data = response.get_json()
        assert data['error'] == 'Service Unavailable'
    
    # ==================== PIPELINE ERRORS ====================
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_returns_503_on_pipeline_not_initialized(self, mock_process, mock_logger_class, client):
        """❌ Pipeline not initialized → 503"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = RuntimeError("Pipeline not initialized")
        
        response = client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        assert response.status_code == 503
        data = response.get_json()
        assert 'pipeline' in data['message'].lower()
    
    # ==================== UNEXPECTED ERRORS ====================
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_returns_500_on_unexpected_error(self, mock_process, mock_logger_class, client):
        """❌ Unexpected error → 500"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = Exception("Unexpected failure")
        
        response = client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        assert response.status_code == 500
        data = response.get_json()
        assert data['error'] == 'Internal Server Error'
        assert 'request_id' in data
    
    # ==================== LOGGING ====================
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_finalizes_logger_on_success(self, mock_process, mock_logger_class, client):
        """✅ Logger finalized on success"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        mock_logger.finalize.assert_called_once()
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_finalizes_logger_on_error(self, mock_process, mock_logger_class, client):
        """✅ Logger finalized even on error"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = Exception("Test error")
        
        client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        mock_logger.finalize.assert_called_once()
    
    # ==================== RESPONSE FORMAT ====================
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_response_has_correct_content_type(self, mock_process, mock_logger_class, client):
        """✅ Response has correct Content-Type header"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        response = client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        assert response.content_type == 'application/json'


class TestFlaskErrorHandlers:
    """Test Flask error handlers"""
    
    def test_404_handler(self, client):
        """❌ Invalid route → 404 with helpful message"""
        
        response = client.get('/nonexistent')
        
        assert response.status_code == 404
        data = response.get_json()
        
        assert data['error'] == 'Not Found'
        assert 'available_endpoints' in data
        assert '/health' in str(data['available_endpoints'])
        assert '/ask' in str(data['available_endpoints'])
    
    def test_405_handler(self, client):
        """❌ Wrong HTTP method → 405"""
        
        # Try GET on /ask (only POST allowed)
        response = client.get('/ask')
        
        assert response.status_code == 405
        data = response.get_json()
        
        assert data['error'] == 'Method Not Allowed'
        assert 'GET' in data['message']


class TestFlaskVsLambdaParity:
    """Ensure Flask and Lambda behave identically"""
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_flask_and_lambda_return_same_response_format(
        self, 
        flask_process, 
        flask_logger_class,
        lambda_process, 
        lambda_logger_class,
        client
    ):
        """✅ Flask and Lambda return identical response structure"""
        from lambda_handler import lambda_handler
        from tests.fixtures.api_gateway_events import create_lambda_event
        
        # Setup mocks
        mock_result = mock_successful_query_result()
        flask_process.return_value = mock_result
        lambda_process.return_value = mock_result
        
        flask_logger = create_mock_logger()
        lambda_logger = create_mock_logger()
        flask_logger_class.return_value = flask_logger
        lambda_logger_class.return_value = lambda_logger
        
        # Test Flask
        flask_response = client.post(
            '/ask',
            json={'text': 'What is RAG?'},
            headers={'Authorization': 'Bearer test-token'}
        )
        flask_data = flask_response.get_json()
        
        # Test Lambda
        lambda_event = create_lambda_event(query="What is RAG?")
        lambda_response = lambda_handler(lambda_event, None)
        lambda_data = json.loads(lambda_response['body'])
        
        # Both should have same structure
        assert flask_data['success'] == lambda_data['success']
        assert flask_data['data']['answer'] == lambda_data['data']['answer']
        assert flask_data['data']['confidence'] == lambda_data['data']['confidence']
    
    @patch('app.AUTH_TOKEN', 'test-token')
    @patch('lambda_handler.SmartRAGLogger')
    @patch('app.SmartRAGLogger')
    def test_flask_and_lambda_handle_errors_identically(
        self,
        flask_logger_class,
        lambda_logger_class,
        client
    ):
        """✅ Flask and Lambda return same error codes"""
        from lambda_handler import lambda_handler
        from tests.fixtures.api_gateway_events import create_lambda_event
        
        mock_logger = create_mock_logger()
        flask_logger_class.return_value = mock_logger
        lambda_logger_class.return_value = mock_logger
        
        # Test empty query in Flask
        flask_response = client.post(
            '/ask',
            json={'text': ''},
            headers={'Authorization': 'Bearer test-token'}
        )
        
        # Test empty query in Lambda
        lambda_event = create_lambda_event(query="")
        
        with patch('lambda_handler.process_query') as lambda_process:
            with patch('app.process_query') as flask_process:
                error = ValueError("Empty query provided")
                flask_process.side_effect = error
                lambda_process.side_effect = error
                
                flask_response = client.post(
                    '/ask',
                    json={'text': ''},
                    headers={'Authorization': 'Bearer test-token'}
                )
                lambda_response = lambda_handler(lambda_event, None)
                
                # Both should return 400
                assert flask_response.status_code == 400
                assert lambda_response['statusCode'] == 400
