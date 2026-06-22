"""
RAG API Client for Streamlit Frontend

Simple HTTP client for communicating with SmartRAG REST API
(Flask or Lambda via API Gateway).

USAGE:
    from helpers.streamline.api_client import RAGAPIClient
    
    client = RAGAPIClient(
        api_url="https://api-id.execute-api.us-east-1.amazonaws.com/prod",
        auth_token="your-bearer-token"
    )
    
    # Ask a question
    result = client.ask_question("What is RAG?")
    if result['success']:
        print(result['data']['answer'])
    
    # Check API health
    health = client.health_check()
    print(health['status'])  # 'healthy' or 'unhealthy'

METHODS:
    ask_question(query: str) -> dict
        Sends POST /ask request with bearer token authentication.
        
        Returns:
            Success: {"success": True, "data": {answer, confidence, sources, request_id}}
            Failure: {"success": False, "error": "error message"}
        
        Handles:
            - Network timeouts (30s default)
            - Connection errors
            - HTTP errors (400, 401, 429, 500, 503)
            - Malformed JSON responses
    
    health_check() -> dict
        Sends GET /health request (no authentication).
        
        Returns:
            Success: {"status": "healthy", "pipeline": "initialized", ...}
            Failure: {"status": "unhealthy"}
        
        Timeout: 5 seconds

CONFIGURATION:
    api_url: Backend API endpoint (trailing slash removed automatically)
        - Flask: http://localhost:5000
        - API Gateway: https://{api-id}.execute-api.{region}.amazonaws.com/prod
    
    auth_token: Bearer token for authentication
        - Must match AUTH_TOKEN on backend

ERROR HANDLING:
    Network Errors:
        - requests.Timeout → {"success": False, "error": "Request timed out"}
        - requests.ConnectionError → {"success": False, "error": "Connection failed"}
    
    HTTP Errors:
        - 401: Invalid token
        - 429: Rate limit (check retry_after_seconds in response)
        - 500: Backend error
        - 503: Pipeline not ready
    
    All errors return dict with "success": False (never raises exceptions)

SECURITY:
    - Bearer token sent via Authorization header
    - Use HTTPS in production (API Gateway enforces this)
    - No token logging/caching

DEPENDENCIES:
    - requests>=2.31.0

TESTING:
    pytest tests/integration/test_streamlit_client.py -v
"""
import requests
import streamlit as st
from typing import Dict, Any

class RAGAPIClient:
    """Client for production RAG API"""
    
    def __init__(self, api_url: str, auth_token: str):
        self.api_url = api_url.rstrip('/')
        self.auth_token = auth_token
        self.headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {auth_token}"
        }
    
    def ask_question(self, query: str) -> Dict[str, Any]:
        """Ask RAG system a question"""
        try:
            response = requests.post(
                f"{self.api_url}/ask",
                headers=self.headers,
                json={"text": query},
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        
        except requests.Timeout:
            return {"success": False, "error": "Request timed out"}
        
        except requests.RequestException as e:
            error_detail = {
                "success": False, 
                "error": str(e),
                "status_code": getattr(e.response, 'status_code', None),
                "response_body": getattr(e.response, 'text', None)
            }
            return error_detail
            
    def health_check(self) -> Dict[str, Any]:
        """Check API health"""
        try:
            response = requests.get(f"{self.api_url}/health", timeout=5)
            return response.json()
        except:
            return {"status": "unhealthy"}

    def submit_feedback(self, request_id: str, feedback:str, comment: str = None) -> Dict[str,Any]:
        """
        Submit user feedback for a response
        Args:
        request_id: The request ID from the original query
        feedback: 'positive' or 'negative'
        comment: Optional text comment explaining the feedback
    
        Returns:
        Dict with 'success' and 'data'/'error'
        
        """

        try:
            payload = {
            "request_id": request_id, 
            "feedback": feedback
        }
        
            # Add comment if provided
            if comment:
                payload["comment"] = comment

            response = requests.post(
                f"{self.api_url}/feedback",
                json = payload,
                headers = self.headers,
                timeout=5
                
                )
            response.raise_for_status()
            return {"success": True, "data": response.json()}
        
        except Exception as e:
            return {"success": False, "error": str(e)}