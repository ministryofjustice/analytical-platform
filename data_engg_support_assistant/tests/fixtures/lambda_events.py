"""
Lambda and API Gateway event fixtures
Reusable event builders for testing
"""
import json
from typing import Dict, Any, Optional


def create_authorizer_event(
    token: Optional[str] = "test-token-123",
    method_arn: str = "arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/POST/ask"
) -> Dict[str, Any]:
    """
    Create API Gateway Lambda Authorizer event (v2.0)
    
    Args:
        token: Bearer token (None for missing token tests)
        method_arn: AWS ARN for the API Gateway method
    
    Returns:
        dict: Authorizer event in API Gateway v2 format
    """
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


def create_lambda_event(
    query: str = "What is RAG?",
    authorizer_context: Optional[Dict[str, Any]] = None,
    include_auth_header: bool = True
) -> Dict[str, Any]:
    """
    Create API Gateway event for main Lambda (POST /ask)
    
    Args:
        query: User query text
        authorizer_context: Context from authorizer (if any)
        include_auth_header: Whether to include Authorization header
    
    Returns:
        dict: Lambda event in API Gateway v2 format
    """
    event = {
        "version": "2.0",
        "routeKey": "POST /ask",
        "rawPath": "/ask",
        "headers": {
            "content-type": "application/json"
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
    
    if include_auth_header:
        event["headers"]["authorization"] = "Bearer test-token-123"
    
    if authorizer_context:
        event["requestContext"]["authorizer"] = authorizer_context
    
    return event
