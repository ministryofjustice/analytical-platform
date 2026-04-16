"""
Lambda Authorizer for API Gateway Token Validation
==================================================

PURPOSE:
    Validates Bearer tokens before allowing requests to reach main Lambda.
    Acts as security gate for API Gateway - only valid tokens pass through.

WHAT THIS DOES:
    1. Extracts Authorization header from incoming request
    2. Removes "Bearer " prefix from token
    3. Compares token with AUTH_TOKEN environment variable
    4. Returns IAM policy: Allow (valid) or Deny (invalid)
    5. API Gateway enforces the policy decision

AUTHORIZATION FLOW:
    API Gateway receives request
         ↓
    Calls this Lambda Authorizer
         ↓
    Extracts token from "Authorization: Bearer " header
         ↓
    Validates: token == AUTH_TOKEN (from environment)
         ↓
    Returns IAM Policy (Allow/Deny)
         ↓
    API Gateway allows/blocks request to main Lambda

WHY IAM POLICY?
    - API Gateway requires IAM policy format for authorization decisions
    - Effect: 'Allow' = request proceeds to main Lambda
    - Effect: 'Deny' = API Gateway returns 403 Forbidden
    - Policy cached by API Gateway (optional, disabled in our setup)

TOKEN VALIDATION:
    ✅ Case-insensitive "Bearer " prefix handling
    ✅ Environment variable comparison (AUTH_TOKEN)
    ✅ Simple string matching (sufficient for testing)
    ❌ Not JWT validation (upgrade to JWT for production)

ENVIRONMENT VARIABLES:
    AUTH_TOKEN: Set by deploy_api_gateway.py from .env file
                This is the "master key" for API access

RESPONSE FORMAT:
    {
        "principalId": "user",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [{
                "Action": "execute-api:Invoke",
                "Effect": "Allow",  # or "Deny"
                "Resource": ""
            }]
        },
        "context": {
            "authenticated": "true"  # Available in main Lambda
        }
    }

SECURITY NOTES:
    - Token stored in Lambda environment variable (encrypted at rest by AWS)
    - Simple string comparison (not cryptographically secure)
    - No token expiration (manual rotation required)
    - Suitable for development/testing only
    - Production: Use JWT with expiration, refresh tokens, Cognito

FAILURE MODES:
    1. Missing Authorization header → Deny
    2. Wrong token → Deny
    3. Empty token → Deny
    4. Token without "Bearer " prefix → Still validated (prefix optional)

    
DEPLOYMENT:
    Deployed automatically by deploy_api_gateway.py:
    1. Packages this file into lambda_authorizer.zip
    2. Creates Lambda function: -authorizer
    3. Sets AUTH_TOKEN environment variable
    4. Attaches to API Gateway as REQUEST authorizer

TESTING:
    # Valid token (should return Allow):
    event = {
        "headers": {"authorization": "Bearer "},
        "routeArn": "arn:aws:execute-api:..."
    }
    
    # Invalid token (should return Deny):
    event = {
        "headers": {"authorization": "Bearer wrong-token"},
        "routeArn": "..."
    }

UPGRADE PATH (Production):
    Replace with JWT validation:
    1. Use PyJWT library
    2. Validate token signature
    3. Check expiration (exp claim)
    4. Verify issuer (iss claim)
    5. Extract user claims (sub, email, roles)
    6. Return user-specific context

TERRAFORM EQUIVALENT:
    resource "aws_lambda_function" "authorizer" {
      filename      = "lambda_authorizer.zip"
      function_name = "${var.function_name}-authorizer"
      handler       = "lambda_authorizer.lambda_handler"
      runtime       = "python3.11"
      timeout       = 10
      memory_size   = 128
      
      environment {
        variables = {
          AUTH_TOKEN = var.auth_token
        }
      }
    }

RELATED FILES:
    - deploy_api_gateway.py: Deploys this authorizer
    - lambda_handler.py: Main Lambda (receives authorized requests)
    - .env: Contains AUTH_TOKEN value

TROUBLESHOOTING:
    - "No authorization header": Client didn't send Authorization header
    - "Invalid token": Token doesn't match AUTH_TOKEN in environment
    - Check CloudWatch Logs for validation attempts
    - Verify AUTH_TOKEN set correctly in Lambda environment
"""
# lambda_authorizer.py. --> Bearer token auth
import os
import json
import hmac
import traceback

def lambda_handler(event, context):
    """
    Lambda Authorizer for REST API Gateway.
    
    Validates Bearer token and returns IAM Policy response.

    REST API format: {'principalId': str, 'policyDocument': {...}, 'context': {...}}
    Args:
        event: API Gateway authorizer event
            - methodArn: ARN of the API method being called
            - headers: HTTP headers including Authorization
        context: Lambda context object
    
    Returns:
        IAM Policy document allowing or denying the request
    """
    request_id = context.aws_request_id if context else 'unknown'
    
    try:
        # Validate methodArn exists (required for REST API authorizers)
        method_arn = event.get('methodArn')
        if not method_arn:
            print(json.dumps({
                'request_id': request_id,
                'level': 'ERROR',
                'message': 'methodArn missing - check authorizer type (should be REQUEST)'
            }))
            return {
                'principalId': 'user',
                'policyDocument': {
                    'Version': '2012-10-17',
                    'Statement': [{
                        'Action': 'execute-api:Invoke',
                        'Effect': 'Deny',
                        'Resource': '*'
                    }]
                }
            }
        
        # Get valid token from environment
        VALID_TOKEN = os.environ.get('AUTH_TOKEN')
        if not VALID_TOKEN:
            print(json.dumps({
                'request_id': request_id,
                'level': 'ERROR',
                'message': 'AUTH_TOKEN not configured'
            }))
            return generate_response(False, event,request_id, 'missing_config')
        
        # Extract token from headers
        headers = event.get('headers', {})
        auth_header = headers.get('authorization') or headers.get('Authorization', '')
        
        if not auth_header:
            print(json.dumps({
                'request_id': request_id,
                'event': 'auth_denied',
                'reason': 'missing_header'
            }))
            return generate_response(False, event,request_id, 'missing_header')
        
        # Remove Bearer prefix (case-insensitive)
        token = auth_header
        if token.lower().startswith('bearer '):
            token = token[7:].strip()
        
        # Validate token (constant-time comparison)
        if hmac.compare_digest(token, VALID_TOKEN):
            print(json.dumps({
                'request_id': request_id,
                'event': 'auth_success'
            }))
            return generate_response(True, event, request_id, 'valid_token')
        else:
            print(json.dumps({
                'request_id': request_id,
                'event': 'auth_denied',
                'reason': 'invalid_token',
                'token_prefix': token[:8] + '...' if len(token) > 8 else 'short_token'
            }))
            return generate_response(False, event, request_id, 'invalid_token')
    
    except Exception as e:
        print(json.dumps({
            'request_id': request_id,
            'level': 'ERROR',
            'error': str(e),
            'stacktrace': traceback.format_exc()
        }))
        return generate_response(False, event, request_id, 'exception')

def generate_response(is_authorized, event, request_id='unknown', reason=''):
    """
    Generate IAM Policy response for REST API Gateway.
    
    Args:
        is_authorized: Boolean indicating if request should be allowed
        event: Original Lambda event (contains methodArn)
        request_id: Request ID for logging
        reason: Human-readable reason for auth decision
    
    Returns:
        IAM Policy document for API Gateway
    """
    effect = 'Allow' if is_authorized else 'Deny'

    method_arn = event.get('methodArn', '*')
    
    # Allow all methods/paths in SAME STAGE only
    if method_arn != '*':
        # Convert: arn:aws:execute-api:region:account:api-id/stage/METHOD/path
        # To:      arn:aws:execute-api:region:account:api-id/stage/*
        arn_parts = method_arn.split('/')
        # Keep stage, wildcard everything after
        resource = f"{arn_parts[0]}/{arn_parts[1]}/*"  # api-id/prod/*
    else:
        resource = '*'
    
    return {
        'principalId': 'user',
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [{
                'Action': 'execute-api:Invoke',
                'Effect': effect,
                'Resource':  resource #api-id/prod/* , specific to prod
            }]
        },
        'context': {
            'requestId': request_id,
            'authenticated': str(is_authorized).lower(),
            'reason': reason
        }
    }
