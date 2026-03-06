"""
Shared authentication decorators for Flask apps.
"""
import os
import time
import hmac
import hashlib
from functools import wraps
from flask import request, jsonify

# Load from config or environment
from config import AUTH_TOKEN, SLACK_SIGNING_SECRET

# Validate at module load
if not AUTH_TOKEN and not os.getenv('IS_LAMBDA'):
    print("[WARN] AUTH_TOKEN not set - bearer auth will reject all requests")
    
def verify_bearer_token(f):
    """
    Validates Bearer token from Authorization header.
    
    Usage:
        @app.route('/ask')
        @verify_bearer_token
        def ask():
            ...
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        if auth_header.lower().startswith('bearer '):
            token = auth_header[7:].strip()
        else:
            token = ''
        
        if not token or not hmac.compare_digest(token, AUTH_TOKEN):
            return jsonify({
                'error': 'Unauthorized',
                'message': 'Invalid or missing Bearer token'
            }), 401
        
        return f(*args, **kwargs)
    return decorated


def verify_slack_signature(f):
    """
    Validates Slack request signature using HMAC-SHA256.
    
    Security features:
    - Replay attack prevention (5-min window)
    - Constant-time signature comparison
    
    Usage:
        @app.route('/slack/events')
        @verify_slack_signature
        def slack_events():
            ...
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        # Check if Slack signing secret is configured
        if not SLACK_SIGNING_SECRET:
            return jsonify({
                'error': 'Service Unavailable',
                'message': 'Slack integration not configured'
            }), 503
        
        timestamp = request.headers.get('X-Slack-Request-Timestamp', '')
        signature = request.headers.get('X-Slack-Signature', '')
        
        if not timestamp or not signature:
            return jsonify({
                'error': 'Unauthorized',
                'message': 'Missing Slack signature headers'
            }), 401
        
        # Check timestamp (prevent replay attacks)
        try:
            request_time = int(timestamp)
            if abs(time.time() - request_time) > 60 * 5:  # 5 minutes
                return jsonify({
                    'error': 'Unauthorized',
                    'message': 'Request timestamp too old'
                }), 401
        except ValueError:
            return jsonify({
                'error': 'Unauthorized',
                'message': 'Invalid timestamp format'
            }), 401
        
        # Verify HMAC signature
        raw_body = request.get_data(as_text=True)
        base_string = f"v0:{timestamp}:{raw_body}"
        computed_signature = 'v0=' + hmac.new(
            SLACK_SIGNING_SECRET.encode(),
            base_string.encode(),
            hashlib.sha256
        ).hexdigest()
        
        if not hmac.compare_digest(computed_signature, signature):
            return jsonify({
                'error': 'Unauthorized',
                'message': 'Invalid Slack signature'
            }), 401
        
        return f(*args, **kwargs)
    return decorated


__all__ = ['verify_bearer_token', 'verify_slack_signature']