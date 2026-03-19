"""
AWS Lambda Handler for SmartRAG Chatbot REST API

Processes POST /ask requests from API Gateway, executes RAG pipeline,
and returns answers with sources and confidence scores.

Event Source: API Gateway HTTP API (v2.0)
Handler: lambda_handler.lambda_handler

Request Format:
    POST /ask
    {
        "text": "What is RAG?"
    }

Response Format:
    {
        "success": true,
        "data": {
            "answer": "...",
            "confidence": 0.92,
            "sources": [...],
            "request_id": "abc-123"
        },
        "metadata": {...}
    }

Error Handling:
    - 400: Invalid request (empty query, malformed JSON)
    - 429: Rate limit exceeded (Bedrock throttling) + Retry-After header
    - 503: Service unavailable (pipeline/Bedrock down)
    - 500: Unexpected errors

Key Features:
    - Lazy pipeline initialization with retry logic
    - Structured logging to CloudWatch via SmartRAGLogger
    - Authorizer context extraction (request ID, auth reason)
    - Automatic logger finalization (ensures logs flush)
    - Bedrock exception translation (ClientError → HTTP status)

Environment Variables:
    - KB_ID: Knowledge Base ID
    - MODEL_ID: Bedrock model (e.g., anthropic.claude-v2)
    - AWS_REGION: AWS region
    - MAX_CONTEXT_TOKENS: Context window size

Dependencies:
    - Layer: smart-rag-dependencies (boto3, langchain, etc.)
    - IAM: Bedrock + CloudWatch Logs permissions
"""

# rest_handler.py --> REST API handler
import sys
import json
import time
import logging
import traceback
from typing import Dict, Any
from datetime import datetime, timezone

# Configure root logger for Lambda infrastructure logs
lambda_logger = logging.getLogger()
lambda_logger.setLevel(logging.INFO)

# Import shared components
from helpers.apug.rag.pipeline_init import get_pipeline
from helpers.apug.rag.query_processor import process_query, format_json_response,BedrockThrottlingError, BedrockServiceError  
from helpers.apug.logging_observability.smart_rag_logger import SmartRAGLogger
from helpers.apug.logging_observability.log_backends import get_log_backends
from helpers.apug.logging_observability.dynamodb_query_utils import update_feedback

# ================== CORS helper function ===============

def get_cors_headers():
    """Standard CORS headers for all responses."""
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    }

def dynamodb_handle_feedback(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle user feedback submission (requries authentication)
    
    Expected body:
    {
        "request_id": "uuid",
        "feedback": "positive" | "negative"
    }
    """

    try:
        # ✓ Check authorization first
        authorizer_data = event.get('requestContext', {}).get('authorizer', {})
        auth_reason = authorizer_data.get('reason', 'unauthorized')
        
        if auth_reason != 'authorized':
            lambda_logger.warning(f"Unauthorized feedback attempt: {auth_reason}")
            return {
                'statusCode': 403,
                'headers': get_cors_headers(),
                'body': json.dumps({
                    'error': 'Forbidden',
                    'message': 'Authentication required'
                })
            }
        
        body = json.loads(event.get('body', '{}'))
        
        # Validate required fields
        request_id = body.get('request_id')
        feedback = body.get('feedback')
        comment = body.get('comment', '')
        
        if not request_id:
            return {
                'statusCode': 400,
                'headers': get_cors_headers(),
                'body': json.dumps({'error': 'Missing request_id'})
            }
        
        if feedback not in ['positive', 'negative']:
            return {
                'statusCode': 400,
                'headers': get_cors_headers(),
                'body': json.dumps({'error': 'Invalid feedback. Must be "positive" or "negative"'})
            }
        
        # Update DynamoDB
        timestamp = datetime.now(timezone.utc).isoformat()
        success = update_feedback(request_id, feedback, timestamp, comment)
        
        if success:
            lambda_logger.info(f"✅ Feedback recorded: {request_id} = {feedback}")
            return {
                'statusCode': 200,
                'headers': get_cors_headers(),
                'body': json.dumps({
                    'message': 'Feedback recorded',
                    'request_id': request_id,
                    'feedback': feedback
                })
            }
        else:
            return {
                'statusCode': 404,
                'headers': get_cors_headers(),
                'body': json.dumps({'error': 'Request ID not found'})
            }
            
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': 'Invalid JSON'})
        }
    except Exception as e:
        lambda_logger.error(f"❌ Feedback handler error: {e}")
        lambda_logger.error(traceback.format_exc())
        return {
            'statusCode': 500,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': 'Internal server error'})
        }


# ==================== REST API HANDLER ====================

def lambda_handler(event, context):
    """
    AWS Lambda handler for REST API requests.
    
    Expected request format (via API Gateway POST /ask):
    {
        "text": "What is RAG?"
    }
    
    Returns:
    {
        "statusCode": 200,
        "body": {
            "success": true,
            "data": {
                "answer": "...",
                "confidence": 0.85,
                "sources": [...]
            }
        }
    }
    """
    # DEBUG: Log raw event
    #print("="*80)
    #print("REST API REQUEST - RAW EVENT:")
    #print(json.dumps(event, indent=2, default=str))
    #print("="*80)

    lambda_logger.info("="*80)
    lambda_logger.info("REST API REQUEST - RAW EVENT:")
    lambda_logger.info(json.dumps(event, indent=2, default=str))
    lambda_logger.info("="*80)

    # Extract route information
    rest_method = event.get('httpMethod', 'POST')
    rest_path = event.get('resource') or event.get('path', '')
    lambda_logger.info(f" Route: {rest_method} {rest_path}")

    # ==================== ROUTING ====================
    
    # OPTIONS requests (CORS preflight)
    if rest_method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': get_cors_headers(),
            'body': ''
        }
    
    # Feedback endpoint
    if rest_path == '/feedback' and rest_method == 'POST':
        return dynamodb_handle_feedback(event)

    if rest_path in ['/ask', '/'] and rest_method == 'POST':
        # Extract authorizer context (user tracking)
        authorizer_data = event.get('requestContext', {}).get('authorizer', {})
        auth_request_id = authorizer_data.get('requestId', 'unknown')
        auth_reason = authorizer_data.get('reason', 'unknown')
        
        #print(f"[AUTH] Request ID: {auth_request_id}, Reason: {auth_reason}")
        lambda_logger.info(f"[AUTH] Request ID: {auth_request_id}, Reason: {auth_reason}")

        start_time = time.time()
        rag_logger = None
        query = None
    
        try:
            # ==================== STEP 1: Parse REST API Request ====================
            parsing_start = time.time()
            
            # Parse body
            body = json.loads(event.get('body', '{}'))
            
            # Extract query text (direct access for REST API)
            query = body.get('text') or body.get('query', '')
            query = query.strip() if query else ''
            
            if not query:
                return {
                    'statusCode': 400,
                    'headers': get_cors_headers(),
                    'body': json.dumps({
                        'error': 'Bad Request',
                        'message': 'Missing "text" field in request body'
                    })
                }
            
            # ==================== STEP 2: Initialize Logger ====================
            #logger = SmartRAGLogger(query=query, backends=get_log_backends())
            rag_logger = SmartRAGLogger(query=query, backends=get_log_backends())

            parsing_duration_ms = (time.time() - parsing_start) * 1000
            rag_logger.log_component(
                component_name="rest_api_parsing",
                duration_ms=parsing_duration_ms,
                metadata={
                    'path': rest_path,
                    'method': rest_method,
                    'source_ip': event.get('requestContext', {}).get('identity', {}).get('sourceIp', 'unknown') # REST API path
                }
            )
            
            # ==================== STEP 3: Process Query (Shared Logic) ====================
            result = process_query(query, rag_logger)
            
            #print(f"[DEBUG] Query processed successfully")
            #print(f"[DEBUG] Answer length: {len(result.get('answer', ''))}")
            #print(f"[DEBUG] Confidence: {result.get('confidence', 0)}")

            lambda_logger.info(f"[DEBUG] Query processed successfully")
            lambda_logger.info(f"[DEBUG] Answer length: {len(result.get('answer', ''))}")
            lambda_logger.info(f"[DEBUG] Confidence: {result.get('confidence', 0)}")
            
            # ==================== STEP 4: Format JSON Response ====================
            formatting_start = time.time()
            json_response = format_json_response(result)
            formatting_duration_ms = (time.time() - formatting_start) * 1000
            
            # Log Lambda overhead
            total_duration_ms = (time.time() - start_time) * 1000
            rag_logger.log_component(
                component_name="rest_api_overhead",
                duration_ms=parsing_duration_ms + formatting_duration_ms,
                metadata={
                    'parsing_ms': parsing_duration_ms,
                    'formatting_ms': formatting_duration_ms,
                    'total_request_ms': total_duration_ms
                }
            )
            
            # ==================== STEP 5: Return Response ====================
            # Before the return statement
            #print(f"[DEBUG] json_response type: {type(json_response)}")
            #print(f"[DEBUG] json_response: {json_response}")

            lambda_logger.info(f"[DEBUG] json_response type: {type(json_response)}")
            lambda_logger.info(f"[DEBUG] body length: {len(json.dumps(json_response))}")
            
            #body_str = json.dumps(json_response)
            #print(f"[DEBUG] body length: {len(body_str)}")
            return {
                'statusCode': 200,
                'headers': get_cors_headers(),
                'body': json.dumps(json_response)
            }

        # ==================== EXCEPTION HANDLERS ====================
        
        except BedrockThrottlingError as e:
            # Rate limit exceeded - return 429
            if rag_logger:
                rag_logger.log_error(e, failed_component='bedrock_throttling')
            
            return {
                'statusCode': 429,
                'headers': {
                    **get_cors_headers(),
                    'Retry-After': str(e.retry_after)
                },
                'body': json.dumps({
                    'error': 'Too Many Requests',
                    'message': 'Rate limit exceeded. Please try again in a few seconds.',
                    'retry_after_seconds': e.retry_after,
                    'error_id': rag_logger.request_id if rag_logger else 'throttle_error'
                })
            }
        
        except BedrockServiceError as e:
            # Bedrock service unavailable - return 503
            if rag_logger:
                rag_logger.log_error(e, failed_component='bedrock_service')
            
            return {
                'statusCode': 503,
                'headers': get_cors_headers(),
                'body': json.dumps({
                    'error': 'Service Unavailable',
                    'message': 'AI service temporarily unavailable. Please try again later.',
                    'error_id': rag_logger.request_id if rag_logger else 'service_error'
                })
            }
        
        # ==================== EXCEPTION HANDLERS ====================
        except json.JSONDecodeError as e:
            # Request body is not valid JSON
            lambda_logger.error(json.dumps({
                "level": "ERROR",
                "error_type": "JSONDecodeError",
                "error_message": "Invalid JSON in request body",
                "details": str(e),
                "stacktrace": traceback.format_exc()
            }))
            
            return {
                'statusCode': 400,
                'headers': get_cors_headers(),
                'body': json.dumps({
                    'error': 'Bad Request',
                    'message': 'Invalid JSON format',
                    'error_id': 'parse_error'
                })
            }
        
        except ValueError as e:
            # Empty query or validation error
            if rag_logger:
                rag_logger.log_error(e, failed_component='input_validation')
            
            return {
                'statusCode': 400,
                'headers': get_cors_headers(),
                'body': json.dumps({
                    'error': 'Bad Request',
                    'message': str(e),
                    'error_id': rag_logger.request_id if rag_logger else 'validation_error'
                })
            }
        
        except RuntimeError as e:
            # Pipeline not initialized
            if rag_logger:
                rag_logger.log_error(e, failed_component='pipeline_init')
            
            return {
                'statusCode': 503,
                'headers': get_cors_headers(),
                'body': json.dumps({
                    'error': 'Service Unavailable',
                    'message': 'RAG pipeline not initialized. Please try again.',
                    'error_id': rag_logger.request_id if rag_logger else 'pipeline_error'
                })
            }
        
        except Exception as e:
            # Unexpected errors
            if rag_logger is None and query:
                try:
                    rag_logger = SmartRAGLogger(query=query, backends=get_log_backends())
                except:
                    pass
            
            if rag_logger:
                rag_logger.log_error(error=e, failed_component='rest_handler')
                error_id = rag_logger.request_id
            else:
                lambda_logger.error(json.dumps({
                    "level": "ERROR",
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                    "query": query if query else "unknown",
                    "stacktrace": traceback.format_exc()
                }))
                error_id = 'unknown'
            
            return {
                'statusCode': 500,
                'headers': get_cors_headers(),
                'body': json.dumps({
                    'error': 'Internal Server Error',
                    'message': 'An unexpected error occurred. Please try again or contact support.',
                    'error_id': error_id
                })
            }
        
        finally:
            # ==================== CRITICAL: Flush Logs ====================
            if rag_logger:
                try:
                    rag_logger.finalize()
                except Exception as flush_error:
                    lambda_logger.error(json.dumps({
                        "level": "ERROR",
                        "error_type": "LoggerFinalizeError",
                        "error_message": str(flush_error),
                        "stacktrace": traceback.format_exc()
                    }))
            
            # Force flush Lambda root logger
            try:
                for handler in lambda_logger.handlers:
                    handler.flush()
                sys.stdout.flush()  # Force stdout flush too
                sys.stderr.flush()
            except Exception as e:
                print(f"[CRITICAL] Logger flush failed: {e}")
