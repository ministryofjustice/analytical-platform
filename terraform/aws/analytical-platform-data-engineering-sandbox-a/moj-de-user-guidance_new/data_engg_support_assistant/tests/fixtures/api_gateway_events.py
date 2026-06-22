"""
Real-world API Gateway event fixtures
Based on AWS documentation and actual events
"""
import json
from typing import Optional, Dict, Any


def create_authorizer_event(
    token: Optional[str] = "valid-token-123",
    method_arn: str = "arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/POST/ask",
    request_id: str = "test-request-123"
) -> Dict[str, Any]:
    """
    Create API Gateway Lambda Authorizer event (v2.0 format)
    
    This is what API Gateway sends to your authorizer Lambda
    """
    return {
        "version": "2.0",
        "type": "REQUEST",
        "routeArn": method_arn,
        "identitySource": [f"Bearer {token}"] if token else [],
        "routeKey": "POST /ask",
        "rawPath": "/ask",
        "rawQueryString": "",
        "headers": {
            "authorization": f"Bearer {token}" if token else "",
            "content-type": "application/json",
            "host": "abcdef123.execute-api.us-east-1.amazonaws.com",
            "user-agent": "curl/7.64.1"
        },
        "requestContext": {
            "accountId": "123456789012",
            "apiId": "abcdef123",
            "domainName": "abcdef123.execute-api.us-east-1.amazonaws.com",
            "domainPrefix": "abcdef123",
            "requestId": request_id,
            "http": {
                "method": "POST",
                "path": "/ask",
                "protocol": "HTTP/1.1",
                "sourceIp": "203.0.113.1",
                "userAgent": "curl/7.64.1"
            },
            "stage": "prod",
            "time": "09/Jan/2024:12:34:56 +0000",
            "timeEpoch": 1704800096000
        }
    }


def create_lambda_event(
    query: str = "What is RAG?",
    authorizer_context: Optional[Dict[str, Any]] = None,
    include_auth_header: bool = True
) -> Dict[str, Any]:
    """
    Create API Gateway event for main Lambda (POST /ask)
    
    This is what API Gateway sends to your main Lambda after authorizer passes
    """
    event = {
        "version": "2.0",
        "routeKey": "POST /ask",
        "rawPath": "/ask",
        "rawQueryString": "",
        "headers": {
            "content-type": "application/json",
            "host": "abcdef123.execute-api.us-east-1.amazonaws.com",
            "user-agent": "python-requests/2.31.0"
        },
        "requestContext": {
            "accountId": "123456789012",
            "apiId": "abcdef123",
            "domainName": "abcdef123.execute-api.us-east-1.amazonaws.com",
            "requestId": "lambda-req-456",
            "http": {
                "method": "POST",
                "path": "/ask",
                "protocol": "HTTP/1.1",
                "sourceIp": "203.0.113.1",
                "userAgent": "python-requests/2.31.0"
            },
            "stage": "prod",
            "time": "09/Jan/2024:12:34:56 +0000",
            "timeEpoch": 1704800096000
        },
        "body": json.dumps({"text": query}),
        "isBase64Encoded": False
    }
    
    # Add authorization header if requested
    if include_auth_header:
        event["headers"]["authorization"] = "Bearer valid-token-123"
    
    # Add authorizer context if provided (this is what authorizer returns)
    if authorizer_context:
        event["requestContext"]["authorizer"] = authorizer_context
    
    return event


def create_authorizer_response(
    is_authorized: bool = True,
    reason: str = "token_valid",
    request_id: str = "auth-req-123"
) -> Dict[str, Any]:
    """
    Create valid authorizer response
    
    This is what your authorizer should return to API Gateway
    """
    return {
        "isAuthorized": is_authorized,
        "context": {
            "reason": reason,
            "requestId": request_id,
            "timestamp": "2024-01-09T12:34:56Z"
        }
    }


def create_invalid_authorizer_response() -> Dict[str, Any]:
    """
    Create INVALID authorizer response (causes 500 error!)
    
    This simulates the bug you experienced:
    - Missing required fields
    - Wrong data types
    - Causes API Gateway to return 500
    """
    return {
        "isAuthorized": True,
        # ❌ Missing 'context' field
        # ❌ This would cause 500 error in API Gateway
    }


# Export all
__all__ = [
    'create_authorizer_event',
    'create_lambda_event',
    'create_authorizer_response',
    'create_invalid_authorizer_response'
]
