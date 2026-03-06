"""
Test main Lambda handler in isolation
Tests Lambda works independently before testing with authorizer
"""
import pytest
import json
from unittest.mock import patch, Mock

# Import Lambda handler
from lambda_handler import lambda_handler

# Import fixtures
from tests.fixtures.api_gateway_events import create_lambda_event
from tests.fixtures.mock_responses import (
    mock_successful_query_result,
    mock_bedrock_throttling_error,
    mock_bedrock_service_error
)
from tests.utils.test_helpers import (
    assert_valid_lambda_response,
    create_mock_logger
)


class TestLambdaHandlerIsolation:
    """Test main Lambda handler works independently"""
    
    # ==================== SUCCESSFUL REQUESTS ====================
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_processes_valid_query(self, mock_process, mock_logger_class):
        """✅ Valid query → 200 response with answer"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        event = create_lambda_event(query="What is RAG?")
        response = lambda_handler(event, None)
        
        # Assert response structure
        body = assert_valid_lambda_response(response, expected_status=200)
        
        # Assert response content
        assert body['success'] is True
        assert 'answer' in body['data']
        assert 'confidence' in body['data']
        assert 'sources' in body['data']
        assert 'request_id' in body['data']
        
        # Verify logger was finalized
        mock_logger.finalize.assert_called_once()
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_handles_authorizer_context(self, mock_process, mock_logger_class):
        """✅ Lambda extracts authorizer context correctly"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        # Event with authorizer context
        authorizer_context = {
            'requestId': 'auth-123',
            'reason': 'token_valid'
        }
        event = create_lambda_event(
            query="What is RAG?",
            authorizer_context=authorizer_context
        )
        
        response = lambda_handler(event, None)
        
        # Should succeed even with authorizer context
        assert_valid_lambda_response(response, expected_status=200)
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_handles_missing_authorizer_context(self, mock_process, mock_logger_class):
        """✅ Lambda works even without authorizer context (direct invoke)"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        # Event WITHOUT authorizer context (direct invoke)
        event = create_lambda_event(query="What is RAG?", authorizer_context=None)
        
        response = lambda_handler(event, None)
        
        # Should still work
        assert_valid_lambda_response(response, expected_status=200)
    
    # ==================== INPUT VALIDATION ERRORS ====================
    
    @patch('lambda_handler.SmartRAGLogger')
    def test_lambda_rejects_empty_query(self, mock_logger_class):
        """❌ Empty query → 400 Bad Request"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        
        event = create_lambda_event(query="")
        
        with patch('lambda_handler.process_query') as mock_process:
            mock_process.side_effect = ValueError("Empty query provided")
            
            response = lambda_handler(event, None)
        
        body = assert_valid_lambda_response(response, expected_status=400)
        assert body['error'] == 'Bad Request'
        assert 'Empty query' in body['message']
    
    @patch('lambda_handler.SmartRAGLogger')
    def test_lambda_rejects_missing_text_field(self, mock_logger_class):
        """❌ Missing 'text' field → 400 Bad Request"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        
        event = create_lambda_event(query="What is RAG?")
        event['body'] = json.dumps({"query": "Wrong field name"})  # Wrong key
        
        response = lambda_handler(event, None)
        
        body = assert_valid_lambda_response(response, expected_status=400)
        assert 'Missing "text" field' in body['message']
    
    @patch('lambda_handler.SmartRAGLogger')
    def test_lambda_rejects_invalid_json(self, mock_logger_class):
        """❌ Invalid JSON → 400 Bad Request"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        
        event = create_lambda_event(query="What is RAG?")
        event['body'] = "not valid json"
        
        response = lambda_handler(event, None)
        
        body = assert_valid_lambda_response(response, expected_status=400)
        assert 'Invalid JSON' in body['message']
    
    # ==================== BEDROCK ERRORS ====================
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_handles_bedrock_throttling(self, mock_process, mock_logger_class):
        """❌ Bedrock throttling → 429 with Retry-After header"""
        from helpers.apug.rag.query_processor import BedrockThrottlingError
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        
        throttling_error = BedrockThrottlingError("Rate exceeded", retry_after=10)
        mock_process.side_effect = throttling_error
        
        event = create_lambda_event(query="What is RAG?")
        response = lambda_handler(event, None)
        
        body = assert_valid_lambda_response(response, expected_status=429)
        assert body['error'] == 'Too Many Requests'
        assert body['retry_after_seconds'] == 10
        assert response['headers']['Retry-After'] == '10'
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_handles_bedrock_service_error(self, mock_process, mock_logger_class):
        """❌ Bedrock service unavailable → 503 Service Unavailable"""
        from helpers.apug.rag.query_processor import BedrockServiceError
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = BedrockServiceError("Service down")
        
        event = create_lambda_event(query="What is RAG?")
        response = lambda_handler(event, None)
        
        body = assert_valid_lambda_response(response, expected_status=503)
        assert body['error'] == 'Service Unavailable'
    
    # ==================== PIPELINE ERRORS ====================
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_handles_pipeline_not_initialized(self, mock_process, mock_logger_class):
        """❌ Pipeline not initialized → 503 Service Unavailable"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = RuntimeError("Pipeline not initialized")
        
        event = create_lambda_event(query="What is RAG?")
        response = lambda_handler(event, None)
        
        body = assert_valid_lambda_response(response, expected_status=503)
        assert 'pipeline' in body['message'].lower()
    
    # ==================== UNEXPECTED ERRORS ====================
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_handles_unexpected_error(self, mock_process, mock_logger_class):
        """❌ Unexpected error → 500 Internal Server Error"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = Exception("Unexpected failure")
        
        event = create_lambda_event(query="What is RAG?")
        response = lambda_handler(event, None)
        
        body = assert_valid_lambda_response(response, expected_status=500)
        assert body['error'] == 'Internal Server Error'
        assert 'error_id' in body
    
    # ==================== LOGGING ====================
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_finalizes_logger_on_success(self, mock_process, mock_logger_class):
        """✅ Logger finalized on successful request"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        event = create_lambda_event(query="What is RAG?")
        lambda_handler(event, None)
        
        mock_logger.finalize.assert_called_once()
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_finalizes_logger_on_error(self, mock_process, mock_logger_class):
        """✅ Logger finalized even when error occurs"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.side_effect = Exception("Test error")
        
        event = create_lambda_event(query="What is RAG?")
        lambda_handler(event, None)
        
        # Logger should be finalized even on error
        mock_logger.finalize.assert_called_once()
    
    # ==================== SPECIAL CHARACTERS ====================
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_lambda_handles_unicode_query(self, mock_process, mock_logger_class):
        """✅ Unicode characters in query should work"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_successful_query_result()
        
        unicode_query = "What is RAG? 日本語 🚀 émojis"
        event = create_lambda_event(query=unicode_query)
        
        response = lambda_handler(event, None)
        
        assert_valid_lambda_response(response, expected_status=200)
        
        # Verify query was passed correctly
        mock_process.assert_called_once()
        actual_query = mock_process.call_args[0][0]
        assert unicode_query in actual_query