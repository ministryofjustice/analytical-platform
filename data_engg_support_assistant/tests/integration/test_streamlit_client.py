"""
Test Streamlit API client
Ensures client handles all error cases gracefully
"""
import pytest
from unittest.mock import patch, Mock
import requests

# Import Streamlit client
from helpers.streamline.api_client import RAGAPIClient


@pytest.fixture
def api_client():
    """Create RAGAPIClient instance"""
    return RAGAPIClient(
        api_url="https://api.example.com",
        auth_token="test-token-123"
    )


class TestRAGAPIClientInitialization:
    """Test client initialization"""
    
    def test_client_initializes_with_url_and_token(self):
        """✅ Client initializes correctly"""
        client = RAGAPIClient(
            api_url="https://api.example.com",
            auth_token="my-token"
        )
        
        assert client.api_url == "https://api.example.com"
        assert client.auth_token == "my-token"
        assert client.headers['Authorization'] == "Bearer my-token"
        assert client.headers['Content-Type'] == "application/json"
    
    def test_client_strips_trailing_slash_from_url(self):
        """✅ Trailing slash removed from API URL"""
        client1 = RAGAPIClient("https://api.example.com/", "token")
        client2 = RAGAPIClient("https://api.example.com", "token")
        
        assert client1.api_url == "https://api.example.com"
        assert client2.api_url == "https://api.example.com"


class TestAskQuestion:
    """Test ask_question() method"""
    
    # ==================== SUCCESSFUL REQUESTS ====================
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_returns_success_response(self, mock_post, api_client):
        """✅ Successful API call → Returns answer"""
        
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'success': True,
            'data': {
                'answer': 'Streamlit is a Python framework.',
                'confidence': 0.90,
                'sources': [{'title': 'Docs', 'score': 0.95}],
                'request_id': 'req-123'
            },
            'metadata': {'total_sources': 1}
        }
        mock_post.return_value = mock_response
        
        result = api_client.ask_question("What is Streamlit?")
        
        # Verify request
        mock_post.assert_called_once_with(
            "https://api.example.com/ask",
            headers={
                "Content-Type": "application/json",
                "Authorization": "Bearer test-token-123"
            },
            json={"text": "What is Streamlit?"},
            timeout=30
        )
        
        # Verify response
        assert result['success'] is True
        assert result['data']['answer'] == 'Streamlit is a Python framework.'
        assert result['data']['confidence'] == 0.90
    
    # ==================== NETWORK ERRORS ====================
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_timeout(self, mock_post, api_client):
        """❌ Request timeout → Returns error dict"""
        
        mock_post.side_effect = requests.Timeout()
        
        result = api_client.ask_question("What is Streamlit?")
        
        assert result['success'] is False
        assert 'timed out' in result['error'].lower()
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_connection_error(self, mock_post, api_client):
        """❌ Connection error → Returns error dict"""
        
        mock_post.side_effect = requests.ConnectionError("Network unreachable")
        
        result = api_client.ask_question("What is Streamlit?")
        
        assert result['success'] is False
        assert 'error' in result
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_dns_error(self, mock_post, api_client):
        """❌ DNS resolution failure → Returns error dict"""
        
        mock_post.side_effect = requests.exceptions.RequestException("DNS lookup failed")
        
        result = api_client.ask_question("What is Streamlit?")
        
        assert result['success'] is False
    
    # ==================== HTTP ERRORS ====================
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_400_error(self, mock_post, api_client):
        """❌ 400 Bad Request → Returns error"""
        
        mock_response = Mock()
        mock_response.status_code = 400
        mock_response.json.return_value = {
            'error': 'Bad Request',
            'message': 'Empty query provided'
        }
        mock_response.raise_for_status.side_effect = requests.HTTPError()
        mock_post.return_value = mock_response
        
        result = api_client.ask_question("")
        
        assert result['success'] is False
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_401_error(self, mock_post, api_client):
        """❌ 401 Unauthorized → Returns error"""
        
        mock_response = Mock()
        mock_response.status_code = 401
        mock_response.json.return_value = {
            'error': 'Unauthorized',
            'message': 'Invalid token'
        }
        mock_response.raise_for_status.side_effect = requests.HTTPError()
        mock_post.return_value = mock_response
        
        result = api_client.ask_question("What is Streamlit?")
        
        assert result['success'] is False
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_429_rate_limit(self, mock_post, api_client):
        """❌ 429 Rate Limit → Returns error with retry info"""
        
        mock_response = Mock()
        mock_response.status_code = 429
        mock_response.headers = {'Retry-After': '10'}
        mock_response.json.return_value = {
            'error': 'Too Many Requests',
            'retry_after_seconds': 10
        }
        mock_response.raise_for_status.side_effect = requests.HTTPError()
        mock_post.return_value = mock_response
        
        result = api_client.ask_question("What is Streamlit?")
        
        assert result['success'] is False
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_500_error(self, mock_post, api_client):
        """❌ 500 Internal Server Error → Returns error (THIS WAS YOUR BUG!)"""
        
        mock_response = Mock()
        mock_response.status_code = 500
        mock_response.json.return_value = {
            'error': 'Internal Server Error',
            'message': 'Authorizer failed'
        }
        mock_response.raise_for_status.side_effect = requests.HTTPError()
        mock_post.return_value = mock_response
        
        result = api_client.ask_question("What is Streamlit?")
        
        # Should not crash, should return error dict
        assert result['success'] is False
        assert 'error' in result
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_503_service_unavailable(self, mock_post, api_client):
        """❌ 503 Service Unavailable → Returns error"""
        
        mock_response = Mock()
        mock_response.status_code = 503
        mock_response.json.return_value = {
            'error': 'Service Unavailable',
            'message': 'Pipeline not initialized'
        }
        mock_response.raise_for_status.side_effect = requests.HTTPError()
        mock_post.return_value = mock_response
        
        result = api_client.ask_question("What is Streamlit?")
        
        assert result['success'] is False
    
    # ==================== MALFORMED RESPONSES ====================
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_invalid_json_response(self, mock_post, api_client):
        """❌ API returns invalid JSON → Returns error"""
        
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.side_effect = ValueError("Invalid JSON")
        mock_post.return_value = mock_response
        
        result = api_client.ask_question("What is Streamlit?")
        
        # Should handle gracefully
        assert result['success'] is False
    
    # ==================== EDGE CASES ====================
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_unicode_query(self, mock_post, api_client):
        """✅ Unicode characters in query"""
        
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'success': True,
            'data': {'answer': 'Answer', 'confidence': 0.8, 'sources': [], 'request_id': '123'}
        }
        mock_post.return_value = mock_response
        
        unicode_query = "What is RAG? 日本語 🚀"
        result = api_client.ask_question(unicode_query)
        
        # Should work
        assert result['success'] is True
        
        # Verify unicode was passed correctly
        call_args = mock_post.call_args
        assert unicode_query in call_args[1]['json']['text']
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_ask_question_handles_very_long_query(self, mock_post, api_client):
        """✅ Very long query (5000 chars)"""
        
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'success': True,
            'data': {'answer': 'Answer', 'confidence': 0.8, 'sources': [], 'request_id': '123'}
        }
        mock_post.return_value = mock_response
        
        long_query = "What is RAG? " * 500  # ~5000 chars
        result = api_client.ask_question(long_query)
        
        assert result['success'] is True


class TestHealthCheck:
    """Test health_check() method"""
    
    @patch('helpers.streamline.api_client.requests.get')
    def test_health_check_returns_healthy(self, mock_get, api_client):
        """✅ Healthy API → Returns healthy status"""
        
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'status': 'healthy',
            'pipeline': 'initialized'
        }
        mock_get.return_value = mock_response
        
        result = api_client.health_check()
        
        mock_get.assert_called_once_with(
            "https://api.example.com/health",
            timeout=5
        )
        
        assert result['status'] == 'healthy'
    
    @patch('helpers.streamline.api_client.requests.get')
    def test_health_check_handles_timeout(self, mock_get, api_client):
        """❌ Health check timeout → Returns unhealthy"""
        
        mock_get.side_effect = requests.Timeout()
        
        result = api_client.health_check()
        
        assert result['status'] == 'unhealthy'
    
    @patch('helpers.streamline.api_client.requests.get')
    def test_health_check_handles_connection_error(self, mock_get, api_client):
        """❌ Connection error → Returns unhealthy"""
        
        mock_get.side_effect = requests.ConnectionError()
        
        result = api_client.health_check()
        
        assert result['status'] == 'unhealthy'
    
    @patch('helpers.streamline.api_client.requests.get')
    def test_health_check_handles_500_error(self, mock_get, api_client):
        """❌ 500 error → Returns unhealthy"""
        
        mock_get.side_effect = requests.RequestException()
        
        result = api_client.health_check()
        
        assert result['status'] == 'unhealthy'


class TestStreamlitResilience:
    """Test that Streamlit UI doesn't crash on backend errors"""
    
    @patch('helpers.streamline.api_client.requests.post')
    def test_client_never_raises_exception(self, mock_post, api_client):
        """✅ Client never raises exceptions (always returns dict)"""
        
        # Test various failure scenarios
        failure_scenarios = [
            requests.Timeout(),
            requests.ConnectionError(),
            requests.HTTPError(),
            requests.RequestException(),
            Exception("Unexpected error")
        ]
        
        for error in failure_scenarios:
            mock_post.side_effect = error
            
            # Should NOT raise exception
            result = api_client.ask_question("Test query")
            
            # Should always return dict with 'success' key
            assert isinstance(result, dict)
            assert 'success' in result
            assert result['success'] is False
