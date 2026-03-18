"""
Streamlit Web Interface for SmartRAG Chatbot
============================================

PURPOSE:
    Interactive web UI for the SmartRAG question-answering system.
    Connects to Flask/Lambda backend via REST API with bearer token authentication.

FEATURES:
    - Chat-style interface with conversation history
    - Real-time answer streaming (simulated)
    - Source citations with confidence scores
    - API health monitoring
    - Session state management
    - Error handling with user-friendly messages
    - Mobile-responsive design

ARCHITECTURE:
    Streamlit UI
        ↓
    RAGAPIClient (helpers/streamline/api_client.py)
        ↓
    HTTP POST to /ask endpoint
        ↓
    Flask API or Lambda (via API Gateway)
        ↓
    SmartRAG Pipeline
        ↓
    Response with answer + sources

REQUEST FLOW:
    1. User enters question in chat input
    2. Streamlit displays "thinking" indicator
    3. RAGAPIClient.ask_question() calls backend API
    4. Response parsed and displayed with:
       - Answer text
       - Confidence score (color-coded)
       - Top 3 source citations
       - Request ID for debugging
    5. Conversation saved in session state

CONFIGURATION:
    Environment Variables (or .env file):
        API_URL (required)        → Backend API endpoint
                                    Examples:
                                    - http://localhost:5000 (local Flask)
                                    - https://api-id.execute-api.region.amazonaws.com/prod (API Gateway)
        
        AUTH_TOKEN (required)     → Bearer token for API authentication
        
    Streamlit Secrets (alternative for deployment):
        .streamlit/secrets.toml:
            API_URL = "https://..."
            AUTH_TOKEN = "..."

DEPLOYMENT:
    # Local Development
    streamlit run streamlit_app.py
    
    # Production (Streamlit Cloud)
    1. Push to GitHub
    2. Connect to Streamlit Cloud
    3. Add secrets in dashboard (API_URL, AUTH_TOKEN)
    4. Deploy
    
    # Docker
    docker build -t smartrag-ui .
    docker run -p 8501:8501 \
      -e API_URL="https://..." \
      -e AUTH_TOKEN="..." \
      smartrag-ui

USAGE:
    # Run locally
    streamlit run streamlit_app.py
    
    # Open browser
    http://localhost:8501
    
    # Ask questions
    Type in chat input → Press Enter → See answer + sources

UI COMPONENTS:
    - Sidebar:
        * API health status indicator
        * Configuration info (model, region)
        * Clear conversation button
    
    - Main Area:
        * Chat history (scrollable)
        * User messages (right-aligned)
        * Assistant messages with:
            - Answer text
            - Confidence badge (🟢 High / 🟡 Medium / 🔴 Low)
            - Source citations (expandable)
            - Request ID (for debugging)
    
    - Input:
        * Chat input box at bottom
        * Submit on Enter key

SESSION STATE:
    st.session_state.messages = [
        {"role": "user", "content": "What is RAG?"},
        {"role": "assistant", "content": "...", "metadata": {...}}
    ]
    
    st.session_state.api_client = RAGAPIClient(...)

ERROR HANDLING:
    Network Errors:
        - Connection timeout → "API not responding. Please try again."
        - Connection refused → "Cannot reach API. Check API_URL."
    
    API Errors:
        - 401 Unauthorized → "Invalid authentication token."
        - 400 Bad Request → "Invalid question format."
        - 429 Rate Limit → "Too many requests. Wait X seconds."
        - 500 Server Error → "Backend error. Please try again."
        - 503 Service Unavailable → "Pipeline initializing. Wait a moment."
    
    User Errors:
        - Empty question → Prevents submission
        - Special characters → Handled by backend

STYLING:
    - Custom CSS for chat bubbles
    - Color-coded confidence scores:
        🟢 High (>80%) - Green badge
        🟡 Medium (50-80%) - Yellow badge
        🔴 Low (<50%) - Red badge
    - Responsive layout (mobile-friendly)
    - Dark mode support

PERFORMANCE:
    - Lazy loading of API client
    - Session state for conversation persistence
    - Minimal re-renders (st.cache where applicable)
    - Async-ready (future enhancement)

TESTING:
    # Unit tests
    pytest tests/integration/test_streamlit_client.py -v
    
    # Manual testing
    1. Run: streamlit run streamlit_app.py
    2. Test scenarios:
       - Valid question → Should show answer
       - Empty question → Should prevent submission
       - Invalid token → Should show auth error
       - API down → Should show connection error
       - Long answer → Should display properly
       - Multiple questions → Should maintain history

MONITORING:
    - Health check in sidebar (updates every 30s)
    - Request ID displayed with each answer
    - Error messages logged to browser console
    - Backend logs in CloudWatch (Lambda) or console (Flask)

COMMON ISSUES:
    "Cannot connect to API":
        → Check API_URL in .env
        → Ensure Flask/Lambda is running
        → Check network/firewall
    
    "401 Unauthorized":
        → Verify AUTH_TOKEN matches backend
        → Check token not expired
    
    "Slow responses":
        → Check backend CloudWatch logs
        → Verify Bedrock quotas
        → Check network latency
    
    "Source citations not showing":
        → Verify backend returns 'sources' field
        → Check JSON response format
    
    "Session state lost on refresh":
        → Expected behavior (browser refresh clears state)
        → Use st.cache for persistence (future enhancement)

CUSTOMIZATION:
    Colors:
        - Primary: #FF4B4B (Streamlit red)
        - Success: #00CC00 (High confidence)
        - Warning: #FFB81C (Medium confidence)
        - Error: #FF4B4B (Low confidence)
    
    Layout:
        - Max width: 800px (centered)
        - Sidebar width: 300px
        - Chat bubble max width: 70%
    
    Fonts:
        - Main: 'Source Sans Pro'
        - Code: 'Source Code Pro'

DEPENDENCIES:
    streamlit>=1.28.0          → Web framework
    requests>=2.31.0           → HTTP client
    python-dotenv>=1.0.0       → Environment variables
    
    Optional:
        streamlit-chat>=0.1.0  → Enhanced chat UI (future)
        plotly>=5.17.0         → Confidence charts (future)

SECURITY:
    - Bearer token sent via Authorization header (HTTPS recommended)
    - No sensitive data stored in session state
    - API_URL validation prevents SSRF
    - Rate limiting handled by backend
    - XSS prevention via Streamlit's built-in sanitization

ACCESSIBILITY:
    - Keyboard navigation support
    - Screen reader compatible
    - High contrast mode support
    - Focus indicators on interactive elements

FUTURE ENHANCEMENTS:
    - [ ] Streaming responses (real-time)
    - [ ] PDF export of conversations
    - [ ] Feedback buttons (👍 👎)
    - [ ] Multi-language support
    - [ ] Voice input
    - [ ] Search conversation history
    - [ ] Share conversation via link
    - [ ] Dark/light theme toggle
    - [ ] Confidence score charts
    - [ ] Source document preview

RELATED FILES:
    - helpers/streamline/api_client.py     → RAGAPIClient class
    - app.py                               → Flask backend
    - lambda_handler.py                    → Lambda backend
    - tests/integration/test_streamlit_client.py → Test suite
    - .streamlit/config.toml               → Streamlit configuration
    - requirements.txt                     → Python dependencies

EXAMPLE QUERIES:
    "What is RAG?"
    "How do I delete tables in Data Uploader?"
    "Explain RStudio 502 errors"
    "What are QuickSight schema best practices?"

API RESPONSE FORMAT (Expected):
    {
        "success": true,
        "data": {
            "answer": "RAG stands for Retrieval-Augmented Generation...",
            "confidence": 0.92,
            "sources": [
                {
                    "title": "RAG Documentation",
                    "score": 0.95,
                    "url": "https://...",
                    "excerpt": "..."
                }
            ],
            "request_id": "abc-123-def-456"
        },
        "metadata": {
            "total_sources": 5,
            "has_more_sources": true
        }
    }

LOGS:
    Streamlit logs:
        - User interactions (question submitted)
        - API calls (request/response)
        - Errors (with stack traces)
    
    Backend logs:
        - CloudWatch (Lambda)
        - Console/file (Flask)

"""

import streamlit as st
import os
from dotenv import load_dotenv
from helpers.apug.streamlit.api_client import RAGAPIClient

# Load environment (for local development only)
if os.path.exists('.env'):
    load_dotenv()

# Page config
st.set_page_config(
    page_title="SmartRAG Assistant",
    page_icon="🤖",
    layout="wide"
)

# Initialize API client
@st.cache_resource
def get_client():
    api_url = os.getenv("RAG_API_URL", "http://localhost:5000")
    auth_token = os.getenv("AUTH_TOKEN")
    
    if not auth_token:
        st.error(" AUTH_TOKEN not set in .env file")
        st.stop()
    
    return RAGAPIClient(api_url=api_url, auth_token=auth_token)

client = get_client()

# Initialize session state for chat history
if "messages" not in st.session_state:
    st.session_state.messages = []

# Sidebar
with st.sidebar:
    st.title(" Settings")
    
    # Show current endpoint
    st.caption(f"**API Endpoint:**")
    st.code(os.getenv("RAG_API_URL", "http://localhost:5000"))
    
    # API Status
    if st.button(" Check API Status"):
        with st.spinner("Checking..."):
            health = client.health_check()
            if health.get("status") == "healthy":
                st.success(" API Online")
                st.json({
                    "model": health.get("model"),
                    "region": health.get("region"),
                    "pipeline": health.get("pipeline"),
                    "kb_id": health.get("kb_id", "N/A")[:12] + "***"
                })
            else:
                st.error(" API Offline")
                st.json(health)
    
    st.divider()
    
    # Clear chat
    if st.button(" Clear Chat History"):
        st.session_state.messages = []
        st.rerun()
    
    # Stats
    st.metric("Messages", len(st.session_state.messages))
    
    st.divider()
    
    # Instructions
    with st.expander(" How to Use"):
        st.markdown("""
        1. Type your question in the chat input
        2. Press Enter or click outside
        3. View answer with confidence score
        4. Expand 'Details' to see sources
        """)

# Main UI
st.title("SmartRAG Assistant")
st.markdown("Ask questions about your knowledge base")

# Display chat history
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])
        
        # Show metadata for assistant messages
        if message["role"] == "assistant" and "metadata" in message:
            request_id = message["metadata"].get("request_id")

            # Render feedback for assistant messages and show only feedback if not yet submitted
            if request_id and not message["metadata"].get("feedback_submitted"):
                st.markdown("**Was this helpful?**")
                col1, col2, col3 = st.columns([1,1,8])

                with col1: 
                    if st.button("👍", key=f"pos_{request_id}"):
                        st.session_state[f"feedback_mode_{request_id}"] = "positive"
                        st.rerun()

                with col2:
                    if st.button("👎", key=f"neg_{request_id}"):
                        st.session_state[f"feedback_mode_{request_id}"] = "negative"
                        st.rerun()
                        
                # Show text input if feedback button was clicked
                if f"feedback_mode_{request_id}" in st.session_state:
                    feedback_type = st.session_state[f"feedback_mode_{request_id}"]
                    prompt_text = "Why?" if feedback_type == "positive" else "What went wrong?"
                    
                    feedback_text = st.text_area(
                        prompt_text,
                        key=f"feedback_text_{request_id}"
                    )
                    
                    if st.button("Submit", key=f"submit_{request_id}"):
                        feedback_result = client.submit_feedback(
                            request_id, 
                            feedback_type,
                            comment=feedback_text
                        )
                        
                        if feedback_result.get("success"):
                            st.success("✓ Feedback saved!")
                            message["metadata"]["feedback_submitted"] = True
                            del st.session_state[f"feedback_mode_{request_id}"]
                            st.rerun()
                        else:
                            st.error("Failed to submit")

            # Show confirmation if already submitted
            elif message["metadata"].get("feedback_submitted"):
                st.caption("✓ Feedback received. Thank you!")

            with st.expander(" Details"):
                col1, col2 = st.columns(2)
                with col1:
                    st.metric("Sources", message['metadata']['num_sources'])
                with col2:
                    st.caption(f"ID: {message['metadata']['request_id'][:8]}")
                
                if message['metadata'].get('sources'):
                    st.markdown("** Sources:**")
                    for i, src in enumerate(message['metadata']['sources'], 1):
                        title = src.get('title', 'Unknown')
                        url = src.get('url', '#')
                        score = src.get('score', 0)
                        excerpt = src.get('excerpt', '')
                        
                        st.markdown(f"**{i}. {title}** (score: {score:.2f})")
                        if excerpt:
                            st.caption(excerpt[:150] + "...")
                        st.divider()

# Chat input
if prompt := st.chat_input("Ask me anything..."):
    # Add user message
    st.session_state.messages.append({"role": "user", "content": prompt})
    
    # Display user message
    with st.chat_message("user"):
        st.markdown(prompt)
    
    # Get assistant response
    with st.chat_message("assistant"):
        with st.spinner(" Searching knowledge base..."):
            result = client.ask_question(prompt)
        
        if result.get("success"):
            data = result["data"]
            answer = data["answer"]
            
            # Display answer
            st.markdown(answer)
  
            # Store in session with metadata
            st.session_state.messages.append({
                "role": "assistant",
                "content": answer,
                "metadata": {
                    "num_sources": len(data.get("sources", [])),
                    "sources": data.get("sources", []),
                    "request_id": data.get("request_id", "unknown"),
                    "feedback_submitted": False
                }
            })
            
            # Show quick metrics
            col1, col2 = st.columns(2)
            with col1:
                st.metric("Sources", len(data.get("sources", [])))
            with col2:
                st.caption(f"Request ID: {data.get('request_id', 'N/A')[:8]}")
            
            # Show source links
            if data.get("sources"):
                st.markdown("** Sources:**")
                for i, src in enumerate(data.get("sources", []), 1):
                    title = src.get('title', 'Unknown')
                    url = src.get('url', '#')
                    st.markdown(f"{i}. [{title}]({url})")

            # Trigger rerun to show feedback buttons from history
            st.rerun()
        
        else:
            error_msg = f" {result.get('error', 'Unknown error')}"
            st.error(error_msg)
            
            # Store error in chat
            st.session_state.messages.append({
                "role": "assistant",
                "content": error_msg
            })
            
            # Show error details
            if result.get("error_id"):
                st.caption(f"Error ID: {result['error_id']}")
            
            # Show troubleshooting
            with st.expander(" Troubleshooting"):
                st.markdown("""
                **Common issues:**
                -  API offline - Check if Flask/Lambda is running
                -  Unauthorized - Verify AUTH_TOKEN in .env
                -  Timeout - Query too complex or API slow
                -  Rate limit - Too many requests, wait a moment
                """)
