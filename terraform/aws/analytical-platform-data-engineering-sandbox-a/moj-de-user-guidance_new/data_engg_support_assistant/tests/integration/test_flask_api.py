"""
Flask REST API Integration Tests
Tests app.py endpoints with mocked dependencies
"""
import pytest
from unittest.mock import patch

# Import fixtures
from tests.fixtures.test_helpers import create_mock_logger


@pytest.mark.integration
@pytest.mark.flask_api
class TestFlaskEndpoints:
    """Test Flask /health and /ask endpoints"""
    
    @patch('app.ask_smart_pipeline', True)
    def test_health_returns_200_when_pipeline_ready(self, flask_client):
        """✅ Pipeline initialized → /health returns 200"""
        response = flask_client.get('/health')
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['status'] == 'healthy'
        assert data['pipeline'] == 'initialized'
    
    @patch('app.ask_smart_pipeline', None)
    def test_health_returns_503_when_pipeline_failed(self, flask_client):
        """❌ Pipeline failed → /health returns 503"""
        response = flask_client.get('/health')
        
        assert response.status_code == 503
        data = response.get_json()
        assert data['status'] == 'unhealthy'
    
    @patch('app.AUTH_TOKEN', 'test-token-123')
    @patch('app.SmartRAGLogger')
    @patch('app.process_query')
    def test_ask_returns_200_with_valid_token(
        self, 
        mock_process, 
        mock_logger_class, 
        flask_client,
        mock_process_query_success
    ):
        """✅ Valid token + query → /ask returns 200"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_process_query_success()
        
        response = flask_client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer test-token-123'}
        )
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['success'] is True
        assert 'answer' in data['data']
    
    @patch('app.AUTH_TOKEN', 'correct-token')
    def test_ask_returns_401_with_wrong_token(self, flask_client):
        """❌ Wrong token → /ask returns 401"""
        response = flask_client.post(
            '/ask',
            json={'text': 'What is Flask?'},
            headers={'Authorization': 'Bearer wrong-token'}
        )
        
        assert response.status_code == 401
        data = response.get_json()
        assert data['error'] == 'Unauthorized'