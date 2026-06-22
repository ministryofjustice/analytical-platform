"""
Flask REST API for SmartRAG Chatbot - Stage 1 (REST API Only)
==============================================================

PURPOSE:
    REST API server for SmartRAG pipeline with Bearer token authentication.
    Clean separation from Slack integration (see app_slack.py for Stage 2).

ARCHITECTURE:
    - Pipeline initialization (shared via pipeline_init.py)
    - Bearer token decorator (from auth_decorators.py)
    - GET /health
    - POST /ask (Bearer auth - demo ready)
    - process_query() shared logic (from query_processor.py)
    - SmartRAGLogger integration
    - Error handling (401, 400, 500, 503)
    - Request tracing with request_id

REQUEST FLOW:
    Client Request
        ↓
    Bearer Token Validation (@verify_bearer_token)
        ↓
    SmartRAGLogger Initialization
        ↓
    process_query() [shared logic]
        ↓
    ask_smart_pipeline Execution
        ↓
    format_json_response()
        ↓
    JSON Response + CloudWatch Logs

ENDPOINTS:
    GET  /health          → Health check (no auth)
                            Returns: pipeline status, model info, timestamp
    
    POST /ask             → Query endpoint with Bearer token auth
                            Headers: Authorization: Bearer 
                            Body: {"text": "your question"}
                            Returns: {success, data: {answer, confidence, sources}, metadata}

DEPLOYMENT:
    Stage 1 (Current):
        - REST API only
        - Bearer token authentication
        - No Slack dependencies
    
    Stage 2 (Future):
        - Use app_slack.py instead
        - Adds /slack/events endpoint
        - Slack signature verification

USAGE:
    # Development
    export AUTH_TOKEN="your-secure-token"
    export AWS_REGION="us-east-1"
    python app.py
    
    # Demo with curl
    curl -X POST http://localhost:5000/ask \
      -H "Authorization: Bearer your-token-here" \
      -H "Content-Type: application/json" \
      -d '{"text": "What is RAG?"}'
    
    # Health check
    curl http://localhost:5000/health
    
    # Production (with gunicorn)
    gunicorn -w 4 -b 0.0.0.0:5000 --timeout 60 app:app

MIGRATION TO STAGE 2:
    When ready for Slack integration:
    1. Switch to app_slack.py
    2. Add SLACK_SIGNING_SECRET environment variable
    3. Configure Slack app webhook: https://your-domain.com/slack/events
    4. No code changes needed (shared components already compatible)

SHARED COMPONENTS:
    - helpers/apug/rag/pipeline_init.py        → ask_smart_pipeline, kb_catalog
    - helpers/apug/rag/query_processor.py      → process_query(), format_json_response()
    - helpers/apug/rag/auth_decorators.py      → verify_bearer_token()
    - helpers/apug/logging_observability/*     → SmartRAGLogger, CloudWatchBackend

CONFIGURATION:
    Environment Variables:
        AUTH_TOKEN (required)      → Bearer token for /ask endpoint
        AWS_REGION (required)      → AWS region for Bedrock/CloudWatch
        FLASK_ENV (optional)       → 'development' or 'production'
        KB_ID (from config.py)     → Knowledge base ID
        MODEL_ID (from config.py)  → Bedrock model ID

ERROR HANDLING:
    400 Bad Request         → Empty query, invalid JSON
    401 Unauthorized        → Missing/invalid Bearer token
    404 Not Found           → Invalid endpoint
    405 Method Not Allowed  → Wrong HTTP method
    429 Too Many Requests   → Bedrock throttling (+ Retry-After header)
    500 Internal Error      → Unexpected exception
    503 Service Unavailable → Pipeline not initialized, Bedrock down

LOGGING:
    - Development: Console output (human-readable)
    - Production: CloudWatch Logs (structured JSON)
    - All requests tracked with request_id
    - Component-level timing breakdown
    - Error stack traces preserved

SECURITY:
    - Bearer token validation (constant-time comparison via hmac.compare_digest)
    - Request tracing for audit
    - No sensitive data in logs
    - CORS disabled by default
    - Rate limiting recommended for production (see flask-limiter)

TESTING:
    # Unit tests
    pytest tests/integration/test_flask_api.py -v
    
    # With coverage
    pytest tests/integration/test_flask_api.py --cov=app --cov-report=html

COMMON ISSUES:
    - 401 Unauthorized: Check AUTH_TOKEN environment variable matches request header
    - 503 Pipeline Error: Run `python -c "from helpers.apug.rag.pipeline_init import get_pipeline; get_pipeline()"`
    - Slow responses: Check Bedrock quotas and CloudWatch for bottlenecks
    - Logger not flushing: Verify CloudWatch IAM permissions

RELATED FILES:
    - lambda_handler.py          → AWS Lambda equivalent (same logic, different wrapper)
    - app_slack.py               → Stage 2 with Slack integration
    - deployment/deploy_lambda.py → Deploy to AWS Lambda
    - tests/integration/test_flask_api.py → Test suite
"""
"""
SmartRAG REST API - Stage 1
Provides Bearer token authenticated /ask endpoint.
"""
import os
import time
import traceback
from flask import Flask, request, jsonify

# Import shared components
from config import MODEL_ID, REGION, KB_ID, AUTH_TOKEN
from helpers.apug.rag.pipeline_init import ask_smart_pipeline
from helpers.apug.rag.query_processor import process_query, format_json_response, BedrockServiceError, BedrockThrottlingError
from helpers.apug.rag.auth_decorators import verify_bearer_token
from helpers.apug.logging_observability.smart_rag_logger import SmartRAGLogger
from helpers.apug.logging_observability.log_backends import get_log_backends

# Flask app
app = Flask(__name__)

# Initialize backends ONCE at module load (not per request)
LOG_BACKENDS = get_log_backends()

# ==================== ROUTES ====================

@app.route('/health', methods=['GET'])
def health():
    """
    Health check endpoint (no authentication required).
    
    Returns:
        200: Service healthy, pipeline initialized
        503: Service unhealthy, pipeline failed
    """
    if ask_smart_pipeline is None:
        return jsonify({
            'status': 'unhealthy',
            'pipeline': 'failed',
            'message': 'Pipeline initialization failed',
            'timestamp': time.time()
        }), 503
    
    return jsonify({
        'status': 'healthy',
        'pipeline': 'initialized',
        'model': MODEL_ID,
        'region': REGION,
        'kb_id': KB_ID,
        'timestamp': time.time()
    }), 200


@app.route('/ask', methods=['POST'])
@verify_bearer_token
def ask():
    """
    REST API endpoint for question answering.
    
    Authentication: Bearer token required
    
    Request:
        POST /ask
        Headers:
            Authorization: Bearer 
            Content-Type: application/json
        Body:
            {
                "text": "What is RAG?"
            }
    
    Response:
        200: Success
            {
                "success": true,
                "data": {
                    "answer": "...",
                    "confidence": 0.85,
                    "sources": [...],
                    "request_id": "abc-123"
                },
                "metadata": {...}
            }
        
        400: Invalid request
        401: Unauthorized
        503: Service unavailable
        500: Internal error
    """
    start_time = time.time()
    logger = None
    
    try:
        # Parse request
        data = request.get_json()
        if not data:
            return jsonify({
                'error': 'Bad Request',
                'message': 'Request body must be JSON'
            }), 400
        
        query = data.get('text', '').strip()
        
        # Initialize logger
        logger = SmartRAGLogger(query=query, backends= LOG_BACKENDS)
        
        # Log request metadata
        logger.log_component(
            component_name="flask_request_parsing",
            duration_ms=(time.time() - start_time) * 1000,
            metadata={
                'endpoint': '/ask',
                'auth_method': 'bearer_token',
                'client_ip': request.remote_addr,
                'user_agent': request.headers.get('User-Agent', 'unknown')
            }
        )
        
        # Process query (shared logic)
        result = process_query(query, logger)
        
        # Format as JSON response
        response = format_json_response(result)
        
        # Log total request time
        total_duration_ms = (time.time() - start_time) * 1000
        logger.log_component(
            component_name="flask_total_request",
            duration_ms=total_duration_ms,
            metadata={'status': 'success', 'endpoint': '/ask'}
        )
        
        return jsonify(response), 200
    
    except BedrockThrottlingError as e:
        if logger:
            logger.log_error(e, failed_component='bedrock_throttling')
        return jsonify({
            'error': 'Too Many Requests',
            'message': 'Rate limit exceeded. Please try again shortly.',
            'retry_after_seconds': e.retry_after,
            'request_id': logger.request_id if logger else 'unknown'
        }), 429, {'Retry-After': str(e.retry_after)}
    
    except BedrockServiceError as e:
        if logger:
            logger.log_error(e, failed_component='bedrock_service')
        return jsonify({
            'error': 'Service Unavailable',
            'message': 'AI service temporarily unavailable.',
            'request_id': logger.request_id if logger else 'unknown'
        }), 503
    
    except ValueError as e:
        # Invalid input (empty query, etc.)
        if logger:
            logger.log_error(e, failed_component='input_validation')
        return jsonify({
            'error': 'Bad Request',
            'message': str(e),
            'request_id': logger.request_id if logger else 'unknown'
        }), 400
    
    except RuntimeError as e:
        # Pipeline not initialized
        if logger:
            logger.log_error(e, failed_component='pipeline_init')
        return jsonify({
            'error': 'Service Unavailable',
            'message': 'Pipeline not initialized',
            'request_id': logger.request_id if logger else 'unknown'
        }), 503
    
    except Exception as e:
        # Unexpected internal error
        if logger:
            logger.log_error(e, failed_component='flask_ask_handler')
        else:
            print(f"[ERROR] {type(e).__name__}: {e}")
            traceback.print_exc()
        
        return jsonify({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred',
            'request_id': logger.request_id if logger else 'unknown'
        }), 500
    
    finally:
        if logger:
            try:
                logger.finalize()
            except Exception as e:
                print(f"[ERROR] Logger finalization failed: {e}")


# ==================== ERROR HANDLERS ====================

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'error': 'Not Found',
        'message': 'Endpoint does not exist',
        'available_endpoints': [
            'GET /health',
            'POST /ask'
        ]
    }), 404


@app.errorhandler(405)
def method_not_allowed(error):
    """Handle 405 errors"""
    return jsonify({
        'error': 'Method Not Allowed',
        'message': f'This endpoint does not support {request.method}'
    }), 405


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    print(f"[ERROR] Internal server error: {error}")
    traceback.print_exc()
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred'
    }), 500


# ==================== MAIN ====================

if __name__ == '__main__':
    print("\n" + "="*70)
    print("  SmartRAG REST API - Stage 1")
    print("="*70)
    print(f"\n Configuration:")
    print(f"   Model:    {MODEL_ID}")
    print(f"   Region:   {REGION}")
    print(f"   KB ID:    {KB_ID}")
    print(f"   Pipeline: {' Initialized' if ask_smart_pipeline else ' Failed'}")
    print(f"   Auth:     Bearer Token ({' Configured' if AUTH_TOKEN else ' Missing'})")
    print(f"   Logging:  {LOG_BACKENDS[0].__class__.__name__}")
    
    print(f"\n Endpoints:")
    print(f"   GET  http://localhost:5000/health")
    print(f"   POST http://localhost:5000/ask")
    
    print(f"\n Test with curl:")
    print(f'''   curl -X POST http://localhost:5000/ask \\
     -H "Authorization: Bearer {AUTH_TOKEN[:4] if AUTH_TOKEN else 'AUTH_TOKEN'}***..." \\
     -H "Content-Type: application/json" \\
     -d '{{"text": "What is RAG?"}}'
    ''')
    
    print("\n" + "="*70)
    print("  Press Ctrl+C to stop")
    print("="*70 + "\n")
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=(os.getenv('FLASK_ENV') == 'development')
    )
