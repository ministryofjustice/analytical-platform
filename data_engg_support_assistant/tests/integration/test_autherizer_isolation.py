"""
Test Lambda Authorizer in isolation
Tests that authorizer works independently before testing integration
"""
import pytest
import sys
from pathlib import Path
from unittest.mock import patch, Mock

# Import authorizer
sys.path.insert(0, str(Path(__file__).parent.parent.parent / 'deployment'))
from lambda_authorizer import lambda_handler as authorizer_handler

# Import fixtures
from tests.fixtures.api_gateway_events import (
    create_authorizer_event,
    create_authorizer_response
)
from tests.utils.test_helpers import assert_valid_authorizer_response


class TestAuthorizerIsolation:
    """Test authorizer Lambda works independently"""
    
    # ==================== SUCCESSFUL AUTHORIZATION ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'valid-token-123'})
    def test_authorizer_allows_valid_token(self):
        """✅ Valid token → isAuthorized: true"""
        event = create_authorizer_event(token="valid-token-123")
        
        response = authorizer_handler(event, None)
        
        assert_valid_authorizer_response(response, should_authorize=True)
        assert response['context']['reason'] == 'token_valid'
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'secret-key'})
    def test_authorizer_case_insensitive_bearer(self):
        """✅ 'bearer' (lowercase) should work"""
        event = create_authorizer_event(token="secret-key")
        event['headers']['authorization'] = 'bearer secret-key'  # lowercase
        
        response = authorizer_handler(event, None)
        
        assert_valid_authorizer_response(response, should_authorize=True)
    
    # ==================== DENIED AUTHORIZATION ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'correct-token'})
    def test_authorizer_denies_wrong_token(self):
        """❌ Wrong token → isAuthorized: false"""
        event = create_authorizer_event(token="wrong-token")
        
        response = authorizer_handler(event, None)
        
        assert_valid_authorizer_response(response, should_authorize=False)
        assert response['context']['reason'] == 'invalid_token'
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'correct-token'})
    def test_authorizer_denies_missing_token(self):
        """❌ Missing token → isAuthorized: false"""
        event = create_authorizer_event(token=None)
        
        response = authorizer_handler(event, None)
        
        assert_valid_authorizer_response(response, should_authorize=False)
        assert response['context']['reason'] == 'missing_token'
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'correct-token'})
    def test_authorizer_denies_malformed_header(self):
        """❌ Malformed Authorization header → isAuthorized: false"""
        event = create_authorizer_event(token="correct-token")
        event['headers']['authorization'] = 'NotBearer correct-token'  # Wrong format
        
        response = authorizer_handler(event, None)
        
        assert_valid_authorizer_response(response, should_authorize=False)
    
    # ==================== CONFIGURATION ISSUES ====================
    
    def test_authorizer_handles_missing_env_var(self):
        """❌ AUTH_TOKEN not set → Deny all requests"""
        with patch.dict('os.environ', {}, clear=True):
            event = create_authorizer_event(token="any-token")
            
            response = authorizer_handler(event, None)
            
            assert_valid_authorizer_response(response, should_authorize=False)
    
    # ==================== RESPONSE FORMAT VALIDATION ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_returns_required_fields(self):
        """✅ Authorizer response contains all required fields"""
        event = create_authorizer_event(token="test-token")
        
        response = authorizer_handler(event, None)
        
        # API Gateway v2 requires these fields
        assert 'isAuthorized' in response
        assert 'context' in response
        assert isinstance(response['isAuthorized'], bool)
        assert isinstance(response['context'], dict)
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_context_values_are_strings(self):
        """✅ All context values must be strings (API Gateway requirement)"""
        event = create_authorizer_event(token="test-token")
        
        response = authorizer_handler(event, None)
        
        # API Gateway requires context values to be strings
        for key, value in response['context'].items():
            assert isinstance(value, str), \
                f"context['{key}'] must be string, got {type(value).__name__}"
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_includes_request_id(self):
        """✅ Authorizer context includes request ID for tracing"""
        event = create_authorizer_event(token="test-token", request_id="trace-123")
        
        response = authorizer_handler(event, None)
        
        assert 'requestId' in response['context']
        assert len(response['context']['requestId']) > 0
    
    # ==================== EDGE CASES ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_handles_empty_string_token(self):
        """❌ Empty string token → Deny"""
        event = create_authorizer_event(token="")
        
        response = authorizer_handler(event, None)
        
        assert_valid_authorizer_response(response, should_authorize=False)
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_handles_whitespace_token(self):
        """❌ Whitespace-only token → Deny"""
        event = create_authorizer_event(token="   ")
        
        response = authorizer_handler(event, None)
        
        assert_valid_authorizer_response(response, should_authorize=False)
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_token_comparison_constant_time(self):
        """✅ Token comparison should use constant-time comparison (security)"""
        # This test verifies hmac.compare_digest is used
        # We can't directly test timing, but we can verify the function is called
        
        with patch('hmac.compare_digest', return_value=True) as mock_compare:
            event = create_authorizer_event(token="test-token")
            response = authorizer_handler(event, None)
            
            # Verify hmac.compare_digest was called (prevents timing attacks)
            mock_compare.assert_called_once()
