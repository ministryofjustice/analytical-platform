""" 
Slack Event
    ↓ (app_mention, message.im)
API Gateway (Event Subscription URL)
    ↓
Lambda Slack Handler
    ├── Parse Slack event
    ├── Extract user query
    ├── Initialize SmartRAGLogger
    ├── Call process_query()
    └── Format Slack response
    ↓
Slack API → Send response back

"""
# lambda_slack_handler.py --> 
import json
import time
import traceback
from typing import Dict, Any

# Import shared components
from helpers.apug.rag.pipeline_init import ask_smart_pipeline
from helpers.apug.rag.query_processor import process_query, format_slack_response
from helpers.apug.logging_observability.smart_rag_logger import SmartRAGLogger
from helpers.apug.logging_observability.log_backends import CloudWatchBackend

CONTAINER_START_TIME = time.time()
# ==================== LAMBDA HANDLER ====================

def lambda_handler(event, context):
    """
    AWS Lambda handler for Slack Events API.
    
    Responsibilities:
        1. Parse Slack event from API Gateway
        2. Initialize SmartRAGLogger
        3. Call process_query() (shared business logic)
        4. Format Slack response
        5. Handle errors
    
    Returns:
        API Gateway response format
    """
    # DEBUG: Log raw event
    print("="*80)
    print("RAW EVENT FROM API GATEWAY:")
    print(json.dumps(event, indent=2, default=str))
    print("="*80)
    
    start_time = time.time()
    logger = None
    query = None
    
    try:
        # ==================== STEP 1: Parse Slack Event ====================
        parsing_start = time.time()
        body = json.loads(event.get('body', '{}'))
        
        # Handle Slack URL verification (setup event)
        if body.get('type') == 'url_verification':
            return {
                'statusCode': 200,
                'body': json.dumps({'challenge': body['challenge']})
            }
        
        # Extract query from Slack event
        slack_event = body.get('event', {})
        query = slack_event.get('text', '').strip()
        
        # Remove bot mention (e.g., "<@U12345> question")
        if query.startswith('<@'):
            query = query.split('>', 1)[-1].strip()
        
        # ==================== STEP 2: Initialize Logger ====================
        logger = SmartRAGLogger(query=query, backends=[CloudWatchBackend()])
        
        parsing_duration_ms = (time.time() - parsing_start) * 1000
        logger.log_component(
            component_name="lambda_slack_parsing",
            duration_ms=parsing_duration_ms,
            metadata={
                'event_type': slack_event.get('type'),
                'user_id': slack_event.get('user'),
                'channel_id': slack_event.get('channel')
            }
        )
        
        # ==================== STEP 3: Process Query ====================
        result = process_query(query, logger)
        print(f"[DEBUG] Result keys: {result.keys()}")
        print(f"[DEBUG] Answer length: {len(result.get('answer', ''))}")
        
        # ==================== STEP 4: Format Slack Response ====================
        formatting_start = time.time()
        slack_response = format_slack_response(result)
        formatting_duration_ms = (time.time() - formatting_start) * 1000
        
        # Log Lambda overhead
        total_duration_ms = (time.time() - start_time) * 1000
        logger.log_component(
            component_name="lambda_overhead",
            duration_ms=parsing_duration_ms + formatting_duration_ms,
            metadata={
                'parsing_ms': parsing_duration_ms,
                'formatting_ms': formatting_duration_ms,
                'total_request_ms': total_duration_ms
            }
        )
        # DEBUG: Log what we're returning
        print(f"[DEBUG] Returning response with {len(slack_response.get('blocks', []))} blocks")
        print(f"[DEBUG] Response preview: {json.dumps(slack_response)[:200]}")
        """ 
        # ==================== STEP 5: Return Response ====================
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps(slack_response)
        }
        """
        
        # ==================== STEP 5: Return Response ====================
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'message': 'Success',
                'answer': result['answer'][:200],
                'confidence': result['confidence']
            })
        }
    
    except json.JSONDecodeError as e:
        # Event parsing failure (before logger initialization)
        print(json.dumps({
            "level": "ERROR",
            "error_type": "JSONDecodeError",
            "error_message": "Invalid Slack event format",
            "details": str(e),
            "stacktrace": traceback.format_exc()
        }))
        
        return {
            'statusCode': 400,
            'body': json.dumps({
                'text': 'Invalid request format.',
                'error_id': 'parse_error'
            })
        }
    
    except ValueError as e:
        # Empty query or validation error
        if logger:
            logger.log_error(e, failed_component='input_validation')
        
        return {
            'statusCode': 400,
            'body': json.dumps({
                'text': str(e),
                'error_id': logger.request_id if logger else 'validation_error'
            })
        }
    
    except RuntimeError as e:
        # Pipeline not initialized
        if logger:
            logger.log_error(e, failed_component='pipeline_init')
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'text': 'Service temporarily unavailable. Please try again.',
                'error_id': logger.request_id if logger else 'pipeline_error'
            })
        }
    
    except Exception as e:
        # Unexpected errors
        if logger is None and query:
            try:
                logger = SmartRAGLogger(query=query, backends=[CloudWatchBackend()])
            except:
                pass
        
        if logger:
            logger.log_error(error=e, failed_component='lambda_handler')
            error_id = logger.request_id
        else:
            print(json.dumps({
                "level": "ERROR",
                "error_type": type(e).__name__,
                "error_message": str(e),
                "query": query if query else "unknown",
                "stacktrace": traceback.format_exc()
            }))
            error_id = 'unknown'
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'text': 'Sorry, something went wrong. Please try again or contact support.',
                'error_id': error_id
            })
        }
    
    finally:
        # ==================== CRITICAL: Flush Logs ====================
        if logger:
            try:
                logger.finalize()
            except Exception as flush_error:
                print(json.dumps({
                    "level": "ERROR",
                    "error_type": "LoggerFinalizeError",
                    "error_message": str(flush_error),
                    "stacktrace": traceback.format_exc()
                }))





