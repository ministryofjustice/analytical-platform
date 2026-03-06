"""
Lambda Handler Integration Tests
Tests lambda_handler.py with mocked dependencies
"""
import pytest
import json
from unittest.mock import patch, Mock

# Import Lambda handler
from lambda_handler import lambda_handler

# Import fixtures
from tests.fixtures.lambda_events import create_lambda_event
from tests.fixtures.test_helpers import (
    assert_valid_lambda_response,
    create_mock_logger
)


@pytest.mark.integration
@pytest.mark.lambda_handler
class TestLambdaHandlerIntegration:
    """Test Lambda handler with mocked pipeline"""
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_valid_query_returns_200(
        self, 
        mock_process, 
        mock_logger_class,
        api_gateway_lambda_event,
        mock_process_query_success
    ):
        """✅ Valid query → 200 with answer"""
        # Setup mocks
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        mock_process.return_value = mock_process_query_success()
        
        # Create event
        event = api_gateway_lambda_event(query="What is RAG?")
        
        # Call Lambda
        response = lambda_handler(event, None)
        
        # Assert response
        body = assert_valid_lambda_response(response, expected_status=200)
        assert body['success'] is True
        assert 'answer' in body['data']
        assert 'confidence' in body['data']
        
        # Verify logger finalized
        mock_logger.finalize.assert_called_once()
    
    @patch('lambda_handler.SmartRAGLogger')
    def test_empty_query_returns_400(
        self, 
        mock_logger_class,
        api_gateway_lambda_event
    ):
        """❌ Empty query → 400 Bad Request"""
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        
        with patch('lambda_handler.process_query') as mock_process:
            mock_process.side_effect = ValueError("Empty query provided")
            
            event = api_gateway_lambda_event(query="")
            response = lambda_handler(event, None)
        
        body = assert_valid_lambda_response(response, expected_status=400)
        assert body['error'] == 'Bad Request'
        assert 'Empty query' in body['message']
    
    @patch('lambda_handler.SmartRAGLogger')
    @patch('lambda_handler.process_query')
    def test_bedrock_throttling_returns_429(
        self, 
        mock_process,
        mock_logger_class,
        api_gateway_lambda_event
    ):
        """❌ Bedrock throttling → 429 with Retry-After"""
        from helpers.apug.rag.query_processor import BedrockThrottlingError
        
        mock_logger = create_mock_logger()
        mock_logger_class.return_value = mock_logger
        
        error = BedrockThrottlingError("Rate exceeded", retry_after=10)
        mock_process.side_effect = error
        
        event = api_gateway_lambda_event(query="What is RAG?")
        response = lambda_handler(event, None)
        
        body = assert_valid_lambda_response(response, expected_status=429)
        assert body['error'] == 'Too Many Requests'
        assert body['retry_after_seconds'] == 10
        assert response['headers']['Retry-After'] == '10'
