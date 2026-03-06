"""
Helper functions for Lambda/Flask/Streamlit tests
"""
import json
from typing import Dict, Any
from unittest.mock import Mock


def assert_valid_lambda_response(
    response: Dict[str, Any], 
    expected_status: int = 200
) -> Dict[str, Any]:
    """
    Assert Lambda response has correct structure
    
    Args:
        response: Lambda handler response
        expected_status: Expected HTTP status code
    
    Returns:
        dict: Parsed response body
    
    Raises:
        AssertionError: If response is invalid
    """
    assert 'statusCode' in response, "Missing statusCode"
    assert 'headers' in response, "Missing headers"
    assert 'body' in response, "Missing body"
    
    assert response['statusCode'] == expected_status, \
        f"Expected status {expected_status}, got {response['statusCode']}"
    
    try:
        body = json.loads(response['body'])
        assert isinstance(body, dict), "Body should be JSON object"
        return body
    except json.JSONDecodeError as e:
        raise AssertionError(f"Response body is not valid JSON: {e}")


def assert_valid_authorizer_response(
    response: Dict[str, Any], 
    should_authorize: bool = True
):
    """
    Assert authorizer response is valid for API Gateway v2
    
    Args:
        response: Authorizer Lambda response
        should_authorize: Expected authorization result
    
    Raises:
        AssertionError: If response is invalid
    """
    assert 'isAuthorized' in response, "Missing isAuthorized (causes 500!)"
    assert isinstance(response['isAuthorized'], bool), "isAuthorized must be boolean"
    
    assert response['isAuthorized'] == should_authorize, \
        f"Expected isAuthorized={should_authorize}, got {response['isAuthorized']}"
    
    if 'context' in response:
        assert isinstance(response['context'], dict), "context must be dict"
        for key, value in response['context'].items():
            assert isinstance(value, str), \
                f"context['{key}'] must be string (causes 500!), got {type(value).__name__}"


def create_mock_logger():
    """Create mock SmartRAGLogger for tests"""
    logger = Mock()
    logger.request_id = 'test-req-123'
    logger.log_component = Mock()
    logger.log_error = Mock()
    logger.log_success = Mock()
    logger.finalize = Mock()
    return logger
