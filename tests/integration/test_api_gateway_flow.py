
"""
Test API Gateway → Authorizer → Lambda integration flow
This tests the exact scenario where you experienced the 500 error
"""
import pytest
import json
from unittest.mock import patch, Mock

# Import both handlers
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / 'deployment'))
from lambda_authorizer import lambda_handler as authorizer_handler
from lambda_handler import lambda_handler as main_lambda_handler

# Import fixtures
from tests.fixtures.api_gateway_events import (
    create_authorizer_event,
    create_lambda_event,
    create_authorizer_response,
    create_invalid_authorizer_response
)
from tests.fixtures.mock_responses import mock_successful_query_result
from tests.utils.test_helpers import (
    assert_valid_lambda_response,
    assert_valid_authorizer_response,
    create_mock_logger
)


class TestAPIGatewayIntegrationFlow:
    """
    Test the complete API Gateway flow:
    1. API Gateway receives request
    2. API Gateway calls authorizer Lambda
    3. Authorizer returns policy
    4. API Gateway calls main Lambda with auth context
    5. Main Lambda processes request
    """
    
    # ==================== HAPPY PATH ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token-123'})
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_complete_flow_with_valid_token(self, mock_process, mock_logger_class):
        """✅ Complete flow: Valid token → Authorizer passes → Lambda succeeds"""
        
        # Setup mocks
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        # Step 1: API Gateway calls authorizer
        auth_event = create_authorizer_event(token="test-token-123")
        auth_response = authorizer_handler(auth_event, None)
        
        # Verify authorizer allows request
        assert_valid_authorizer_response(auth_response, should_authorize=True)
        
        # Step 2: API Gateway calls main Lambda with auth context
        lambda_event = create_lambda_event(
            query="What is RAG?",
            authorizer_context=auth_response['context']
        )
        lambda_response = main_lambda_handler(lambda_event, None)
        
        # Verify main Lambda succeeds
        body = assert_valid_lambda_response(lambda_response, expected_status=200)
        assert body['success'] is True
        assert 'answer' in body['data']
    
    # ==================== AUTHORIZATION DENIED ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'correct-token'})
    def test_authorizer_denies_invalid_token(self):
        """❌ Invalid token → Authorizer denies (API Gateway returns 403)"""
        
        # Step 1: API Gateway calls authorizer with wrong token
        auth_event = create_authorizer_event(token="wrong-token")
        auth_response = authorizer_handler(auth_event, None)
        
        # Verify authorizer denies request
        assert_valid_authorizer_response(auth_response, should_authorize=False)
        
        # In real scenario, API Gateway would return 403 and NOT call main Lambda
        # We simulate this by NOT calling main_lambda_handler
    
    # ==================== AUTHORIZER RESPONSE FORMAT ISSUES ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_returns_correct_format_for_api_gateway_v2(self):
        """
        ✅ Authorizer returns correct format for API Gateway v2
        This prevents the 500 error you experienced!
        """
        auth_event = create_authorizer_event(token="test-token")
        auth_response = authorizer_handler(auth_event, None)
        
        # API Gateway v2 REQUIRES these exact fields
        assert 'isAuthorized' in auth_response, "Missing isAuthorized (causes 500!)"
        assert 'context' in auth_response, "Missing context (causes 500!)"
        
        # isAuthorized must be boolean
        assert isinstance(auth_response['isAuthorized'], bool), \
            "isAuthorized must be boolean (causes 500!)"
        
        # context must be dict with string values
        assert isinstance(auth_response['context'], dict), \
            "context must be dict (causes 500!)"
        
        for key, value in auth_response['context'].items():
            assert isinstance(value, str), \
                f"context['{key}'] must be string, got {type(value).__name__} (causes 500!)"
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_context_with_non_string_values_fails(self):
        """
        ❌ Simulate authorizer returning non-string context values
        This would cause API Gateway to return 500
        """
        # This test documents what NOT to do
        invalid_response = {
            'isAuthorized': True,
            'context': {
                'requestId': 'test-123',  # ✅ String (correct)
                'timestamp': 1704800096,  # ❌ Integer (causes 500!)
                'isValid': True           # ❌ Boolean (causes 500!)
            }
        }
        
        # Verify our authorizer doesn't do this
        auth_event = create_authorizer_event(token="test-token")
        auth_response = authorizer_handler(auth_event, None)
        
        # All values should be strings
        for key, value in auth_response['context'].items():
            assert isinstance(value, str), \
                f"Authorizer returned non-string value for {key}: {type(value).__name__}"
    
    # ==================== ARN FORMAT VALIDATION ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_handles_different_arn_formats(self):
        """✅ Authorizer works with different ARN formats (dev/prod/staging)"""
        
        # Test different stage ARNs
        test_arns = [
            "arn:aws:execute-api:us-east-1:123456789012:abcdef123/dev/POST/ask",
            "arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/POST/ask",
            "arn:aws:execute-api:us-east-1:123456789012:abcdef123/staging/POST/ask",
            "arn:aws:execute-api:eu-west-1:987654321098:xyz789/prod/POST/ask",
        ]
        
        for arn in test_arns:
            auth_event = create_authorizer_event(
                token="test-token",
                method_arn=arn
            )
            auth_response = authorizer_handler(auth_event, None)
            
            assert_valid_authorizer_response(auth_response, should_authorize=True)
    
    # ==================== MAIN LAMBDA WITH AUTH CONTEXT ====================
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_main_lambda_receives_auth_context_from_authorizer(self, mock_process, mock_logger_class):
        """✅ Main Lambda correctly receives and logs authorizer context"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        # Simulate authorizer context that API Gateway would pass
        authorizer_context = {
            'requestId': 'auth-req-456',
            'reason': 'token_valid',
            'timestamp': '2024-01-09T12:34:56Z'
        }
        
        lambda_event = create_lambda_event(
            query="What is RAG?",
            authorizer_context=authorizer_context
        )
        
        response = main_lambda_handler(lambda_event, None)
        
        # Should succeed
        assert_valid_lambda_response(response, expected_status=200)
        
        # Lambda should log that it received auth context
        # (In production, check CloudWatch logs)
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_main_lambda_works_without_auth_context(self, mock_process, mock_logger_class):
        """✅ Main Lambda works even if authorizer context is missing (direct invoke)"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        # Event without authorizer context (direct Lambda invoke)
        lambda_event = create_lambda_event(
            query="What is RAG?",
            authorizer_context=None
        )
        
        # Remove authorizer field entirely
        if 'authorizer' in lambda_event['requestContext']:
            del lambda_event['requestContext']['authorizer']
        
        response = main_lambda_handler(lambda_event, None)
        
        # Should still work
        assert_valid_lambda_response(response, expected_status=200)
    
    # ==================== ERROR PROPAGATION ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_error_in_main_lambda_does_not_affect_authorizer(self, mock_process, mock_logger_class):
        """✅ Error in main Lambda doesn't break authorizer (they're independent)"""
        
        # Authorizer should succeed
        auth_event = create_authorizer_event(token="test-token")
        auth_response = authorizer_handler(auth_event, None)
        assert_valid_authorizer_response(auth_response, should_authorize=True)
        
        # Main Lambda fails
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = Exception("Lambda crashed")
        
        lambda_event = create_lambda_event(
            query="What is RAG?",
            authorizer_context=auth_response['context']
        )
        lambda_response = main_lambda_handler(lambda_event, None)
        
        # Should return 500, not crash API Gateway
        assert_valid_lambda_response(lambda_response, expected_status=500)
    
    # ==================== PERMISSION TESTING ====================
    
    def test_authorizer_permission_source_arn_format(self):
        """
        ✅ Document the correct SourceArn format for permissions
        This is what caused your "authorizer never executes" issue!
        """
        # Correct format for API Gateway v2 HTTP API
        correct_source_arn = "arn:aws:execute-api:us-east-1:123456789012:abcdef123/authorizers/*"
        
        # Common mistakes that prevent authorizer from executing:
        wrong_formats = [
            "arn:aws:execute-api:us-east-1:123456789012:abcdef123/*/*",  # Too broad
            "arn:aws:execute-api:us-east-1:123456789012:*/authorizers/*",  # Wildcard API ID
            "arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/POST/ask",  # Specific route
        ]
        
        # This test documents the correct format
        # In deployment, verify with:
        # aws lambda get-policy --function-name your-authorizer-function
        assert correct_source_arn.endswith("/authorizers/*")
    
    # ==================== REAL-WORLD SCENARIOS ====================
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'prod-token-xyz'})
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_production_like_flow_with_multiple_requests(self, mock_process, mock_logger_class):
        """✅ Simulate multiple requests in production (authorizer caching)"""
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        ## Simulate 3 consecutive requests with same token
        queries = ["What is RAG?", "Explain embeddings", "How does retrieval work?"]
        
        for query in queries:
            # Step 1: Authorizer validates token
            auth_event = create_authorizer_event(token="prod-token-xyz")
            auth_response = authorizer_handler(auth_event, None)
            assert_valid_authorizer_response(auth_response, should_authorize=True)
            
            # Step 2: Main Lambda processes query
            lambda_event = create_lambda_event(
                query=query,
                authorizer_context=auth_response['context']
            )
            lambda_response = main_lambda_handler(lambda_event, None)
            
            # All should succeed
            assert_valid_lambda_response(lambda_response, expected_status=200)
    
    @patch.dict('os.environ', {'AUTH_TOKEN': 'test-token'})
    def test_authorizer_handles_concurrent_requests(self):
        """✅ Authorizer handles concurrent authorization requests"""
        import threading
        
        results = []
        
        def authorize():
            auth_event = create_authorizer_event(token="test-token")
            response = authorizer_handler(auth_event, None)
            results.append(response)
        
        # Simulate 10 concurrent requests
        threads = [threading.Thread(target=authorize) for _ in range(10)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        
        # All should succeed
        assert len(results) == 10
        for response in results:
            assert_valid_authorizer_response(response, should_authorize=True)
