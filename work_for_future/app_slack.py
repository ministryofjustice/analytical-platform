"""
SmartRAG REST API + Slack - Stage 2
Provides both REST API and Slack Events API integration.
"""
import os
import time
import traceback
from flask import Flask, request, jsonify

# Import shared components
from config import MODEL_ID, REGION, KB_ID, AUTH_TOKEN
from helpers.apug.rag.pipeline_init import ask_smart_pipeline
from helpers.apug.rag.query_processor import (
    process_query, 
    format_json_response, 
    format_slack_response
)
from helpers.apug.rag.auth_decorators import (
    verify_bearer_token, 
    verify_slack_signature
)
from helpers.apug.logging_observability.smart_rag_logger import SmartRAGLogger
from helpers.apug.logging_observability.log_backends import CloudWatchBackend

# Flask app
app = Flask(__name__)

# Slack configuration
SLACK_SIGNING_SECRET = os.getenv('SLACK_SIGNING_SECRET', '')


# ==================== LOGGING CONFIGURATION ====================

def get_log_backends():
    """Return appropriate log backends based on environment."""
    backends = []
    
    if os.getenv('FLASK_ENV') == 'development':
        from helpers.apug.logging_observability.log_backends import ConsoleBackend
        backends.append(ConsoleBackend())
    else:
        try:
            backends.append(CloudWatchBackend())
        except Exception as e:
            print(f"[WARN] CloudWatch unavailable: {e}")
            from helpers.apug.logging_observability.log_backends import ConsoleBackend
            backends.append(ConsoleBackend())
    
    return backends


# ==================== REST API ROUTES ====================

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    if ask_smart_pipeline is None:
        return jsonify({
            'status': 'unhealthy',
            'pipeline': 'failed',
            'message': 'Pipeline initialization failed',
            'timestamp': time.time()
        }), 503
    
    slack_configured = bool(SLACK_SIGNING_SECRET)
    
    return jsonify({
        'status': 'healthy',
        'pipeline': 'initialized',
        'model': MODEL_ID,
        'region': REGION,
        'kb_id': KB_ID,
        'integrations': {
            'rest_api': True,
            'slack': slack_configured
        },
        'timestamp': time.time()
    }), 200


@app.route('/ask', methods=['POST'])
@verify_bearer_token
def ask():
    """REST API endpoint (same as app.py)."""
    start_time = time.time()
    logger = None
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({
                'error': 'Bad Request',
                'message': 'Request body must be JSON'
            }), 400
        
        query = data.get('text', '').strip()
        logger = SmartRAGLogger(query=query, backends=get_log_backends())
        
        logger.log_component(
            component_name="flask_request_parsing",
            duration_ms=(time.time() - start_time) * 1000,
            metadata={
                'endpoint': '/ask',
                'auth_method': 'bearer_token',
                'client_ip': request.remote_addr
            }
        )
        
        result = process_query(query, logger)
        response = format_json_response(result)
        
        total_duration_ms = (time.time() - start_time) * 1000
        logger.log_component(
            component_name="flask_total_request",
            duration_ms=total_duration_ms,
            metadata={'status': 'success', 'endpoint': '/ask'}
        )
        
        return jsonify(response), 200
    
    except ValueError as e:
        if logger:
            logger.log_error(e, failed_component='input_validation')
        return jsonify({
            'error': 'Bad Request',
            'message': str(e),
            'request_id': logger.request_id if logger else 'unknown'
        }), 400
    
    except RuntimeError as e:
        if logger:
            logger.log_error(e, failed_component='pipeline_init')
        return jsonify({
            'error': 'Service Unavailable',
            'message': 'Pipeline not initialized',
            'request_id': logger.request_id if logger else 'unknown'
        }), 503
    
    except Exception as e:
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


# ==================== SLACK ROUTES ====================

@app.route('/slack/events', methods=['POST'])
@verify_slack_signature
def slack_events():
    """
    Slack Events API endpoint.
    
    Handles:
    - URL verification (Slack setup)
    - app_mention events
    - message events
    """
    start_time = time.time()
    logger = None
    
    try:
        body = request.get_json()
        
        # Handle Slack URL verification challenge
        if body.get('type') == 'url_verification':
            return jsonify({'challenge': body['challenge']}), 200
        
        # Extract event data
        slack_event = body.get('event', {})
        event_type = slack_event.get('type')
        
        # Ignore bot messages (prevent loops)
        if slack_event.get('bot_id'):
            return jsonify({'ok': True}), 200
        
        # Extract query text
        query = slack_event.get('text', '').strip()
        
        # Remove bot mention (e.g., "<@U12345> question")
        if query.startswith('<@'):
            query = query.split('>', 1)[-1].strip()
        
        # Initialize logger
        logger = SmartRAGLogger(query=query, backends=get_log_backends())
        
        # Log Slack event metadata
        logger.log_component(
            component_name="slack_event_parsing",
            duration_ms=(time.time() - start_time) * 1000,
            metadata={
                'event_type': event_type,
                'user_id': slack_event.get('user'),
                'channel_id': slack_event.get('channel')
            }
        )
        
        # Process query (shared logic)
        result = process_query(query, logger)
        
        # Format as Slack blocks
        slack_response = format_slack_response(result)
        
        # Log total request time
        total_duration_ms = (time.time() - start_time) * 1000
        logger.log_component(
            component_name="slack_total_request",
            duration_ms=total_duration_ms,
            metadata={'status': 'success'}
        )
        
        return jsonify(slack_response), 200
    
    except ValueError as e:
        # Empty query
        if logger:
            logger.log_error(e, failed_component='input_validation')
        return jsonify({
            'text': str(e),
            'blocks': [{
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': f"⚠️ *Error:* {str(e)}\n\n*Request ID:* `{logger.request_id if logger else 'unknown'}`"
                }
            }]
        }), 200  # Return 200 to prevent Slack retries
    
    except RuntimeError as e:
        # Pipeline not initialized
        if logger:
            logger.log_error(e, failed_component='pipeline_init')
        return jsonify({
            'text': 'Service temporarily unavailable. Please try again.',
            'blocks': [{
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': f"⚠️ *Error:* Service unavailable\n\n*Request ID:* `{logger.request_id if logger else 'unknown'}`"
                }
            }]
        }), 200
    
    except Exception as e:
        if logger:
            logger.log_error(e, failed_component='slack_events_handler')
        else:
            print(f"[ERROR] {type(e).__name__}: {e}")
            traceback.print_exc()
        
        return jsonify({
            'text': 'Sorry, something went wrong. Please try again.',
            'blocks': [{
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': f"⚠️ *Error:* An unexpected error occurred.\n\n*Request ID:* `{logger.request_id if logger else 'unknown'}`"
                }
            }]
        }), 200
    
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
            'POST /ask',
            'POST /slack/events'
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
    print("  SmartRAG REST API + Slack - Stage 2")
    print("="*70)
    print(f"\n📋 Configuration:")
    print(f"   Model:    {MODEL_ID}")
    print(f"   Region:   {REGION}")
    print(f"   KB ID:    {KB_ID}")
    print(f"   Pipeline: {'✅ Initialized' if ask_smart_pipeline else '❌ Failed'}")
    print(f"   REST API: {'✅ Configured' if AUTH_TOKEN else '❌ Missing token'}")
    print(f"   Slack:    {'✅ Configured' if SLACK_SIGNING_SECRET else '⚠️  Not configured (optional)'}")
    
    print(f"\n🌐 Endpoints:")
    print(f"   GET  http://localhost:5000/health")
    print(f"   POST http://localhost:5000/ask (Bearer token)")
    print(f"   POST http://localhost:5000/slack/events (Slack signature)")
    
    print(f"\n🧪 Test REST API:")
    print(f'''   curl -X POST http://localhost:5000/ask \\
     -H "Authorization: Bearer {AUTH_TOKEN[:10] if AUTH_TOKEN else 'YOUR_TOKEN'}..." \\
     -H "Content-Type: application/json" \\
     -d '{{"text": "What is RAG?"}}'
    ''')
    
    if SLACK_SIGNING_SECRET:
        print(f"\n💬 Slack Integration:")
        print(f"   Configure in Slack App > Event Subscriptions:")
        print(f"   Request URL: https://your-domain.com/slack/events")
    
    print("\n" + "="*70)
    print("  Press Ctrl+C to stop")
    print("="*70 + "\n")
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=(os.getenv('FLASK_ENV') == 'development')
    )
