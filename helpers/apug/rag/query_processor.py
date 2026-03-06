"""
Query Processing Module
=======================

PURPOSE:
    Shared business logic for processing queries through the SmartRAG pipeline.
    Used by both Lambda (production) and Flask (development).

RESPONSIBILITIES:
    1. Validate query input
    2. Execute pipeline with logging
    3. Format responses (JSON and Slack Block Kit)
    4. Handle errors gracefully

DESIGN:
    - AWS/Slack agnostic (pure business logic)
    - Takes logger as dependency injection
    - Returns structured data (not HTTP responses)

process_query() - Core business logic (validates + calls pipeline)
format_slack_response() - Slack Block Kit formatting
format_json_response() - REST API formatting
"""

import time
from typing import Dict, Any, Optional
from botocore.exceptions import ClientError
from helpers.apug.rag.pipeline_init import get_pipeline
from helpers.apug.logging_observability.smart_rag_logger import SmartRAGLogger


# ==================== QUERY PROCESSING ====================

def process_query(query_text: str, logger: SmartRAGLogger) -> Dict[str, Any]:
    """
    Process user query through SmartRAG pipeline.
    
    Args:
        query_text: User's question/query
        logger: SmartRAGLogger instance for request tracking
    
    Returns:
        dict: {
            'answer': str,              # Generated answer
            'confidence': float,        # 0.0 to 1.0
            'sources': list,            # Top source documents
            'request_id': str,          # For tracing/debugging
            'validation_issues': list   # Any validation warnings
        }
    
    Raises:
        ValueError: If query is empty/invalid
        RuntimeError: If pipeline not initialized
        Exception: Pipeline execution errors (propagated to caller)
    
    Design:
        - Validates inputs before pipeline execution
        - Logs component-level timing via SmartRAGLogger
        - Returns structured data (caller formats HTTP/Slack response)
    """
    # Validate query
    if not query_text or not query_text.strip():
        logger.log_error(
            ValueError("Empty query provided"),
            failed_component='input_validation'
        )
        raise ValueError("Empty query provided")
    
    #  Get pipeline with lazy initialization
    pipeline, catalog = get_pipeline()
    
    # Check pipeline initialization
    if pipeline is None:
        logger.log_error(
            RuntimeError("Pipeline not initialized - check initialization logs"),
            failed_component='pipeline_init'
        )
        raise RuntimeError("Pipeline not initialized")
    
    # Execute pipeline
    pipeline_start = time.time()
    
    try:
        # Call AskSmart pipeline (logger passed for component tracking)
        result = pipeline.ask(
            query=query_text, 
            verbose=False,  # Suppress console output (use logger instead)
            logger=logger
        )
        
        pipeline_duration_ms = (time.time() - pipeline_start) * 1000
        
        # Log pipeline execution metadata
        logger.log_component(
            component_name="ask_smart_pipeline_execution",
            duration_ms=pipeline_duration_ms,
            metadata={
                'confidence': result.confidence,
                'num_sources': len(result.sources) if result.sources else 0,
                'has_validation_issues': bool(result.validation_issues) if hasattr(result, 'validation_issues') else False
            }
        )
        
        # Format response
        return {
            'answer': result.answer,
            'confidence': result.confidence,
            'sources': result.sources[:3] if result.sources else [],  # Top 3 sources
            'request_id': logger.request_id,
            'validation_issues': result.validation_issues if hasattr(result, 'validation_issues') else []
        }
    
    # ==================== BEDROCK-SPECIFIC EXCEPTIONS ====================
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        
        # Log the Bedrock error
        logger.log_component(
            component_name="bedrock_error",
            duration_ms=(time.time() - pipeline_start) * 1000,
            metadata={
                'error_code': error_code,
                'error_message': error_message,
                'request_id': e.response.get('ResponseMetadata', {}).get('RequestId', 'unknown')
            }
        )
        
        # Throttling - Too many requests
        if error_code == 'ThrottlingException':
            logger.log_error(e, failed_component='bedrock_throttling')
            # Re-raise with custom exception type for caller to handle 429
            error = BedrockThrottlingError(
                message=f"Bedrock API rate limit exceeded: {error_message}",
                retry_after=5  # Suggest retry after 5 seconds
            )
            error.original_error = e
            raise error
        
        # Validation errors - Invalid request format
        elif error_code == 'ValidationException':
            logger.log_error(e, failed_component='bedrock_validation')
            # Re-raise as ValueError for 400 handling
            raise ValueError(f"Invalid request to Bedrock: {error_message}")
        
        # Model not found or access denied
        elif error_code in ['ResourceNotFoundException', 'AccessDeniedException']:
            logger.log_error(e, failed_component='bedrock_access')
            raise RuntimeError(f"Bedrock access error: {error_message}")
        
        # Service unavailable
        elif error_code in ['ServiceUnavailableException', 'InternalServerException']:
            logger.log_error(e, failed_component='bedrock_service')
            error = BedrockServiceError(message=f"Bedrock service error: {error_message}")
            error.original_error = e
            raise error
        
        # Unknown Bedrock error
        else:
            logger.log_error(e, failed_component='bedrock_unknown')
            raise
    
    # ==================== OTHER EXCEPTIONS ====================    
    except Exception as e:
        # Log pipeline error
        logger.log_error(
            error=e,
            failed_component='ask_smart_pipeline'
        )
        # Re-raise for caller to handle (Lambda/Flask specific error responses)
        raise

# ==================== CUSTOM EXCEPTION CLASSES ====================

class BedrockThrottlingError(Exception):
    """Raised when Bedrock API rate limit is exceeded."""
    def __init__(self, message: str, retry_after: int = 5):
        super().__init__(message)
        self.retry_after = retry_after
        self.original_error = None


class BedrockServiceError(Exception):
    """Raised when Bedrock service is unavailable."""
    def __init__(self, message: str):
        super().__init__(message)
        self.original_error = None



# ==================== RESPONSE FORMATTING ====================

def format_slack_response(result: Dict[str, Any], request_id: Optional[str] = None) -> Dict[str, Any]:
    """
    Convert query result to Slack Block Kit format.
    
    Args:
        result: Output from process_query() or direct SmartAnswer object
        request_id: Optional request ID (extracted from result if not provided)
    
    Returns:
        dict: Slack Block Kit JSON with:
            - Answer text (markdown formatted)
            - Top 3 sources with confidence scores
            - Confidence indicator (🟢 high, 🟡 medium, 🔴 low)
            - Request ID for debugging
            - Validation warnings (if present)
    
    Design:
        - Rich formatting using Slack Block Kit
        - Color-coded confidence levels
        - Expandable source citations
        - Traceability via request ID
    """
    # Extract request_id if not provided
    if request_id is None:
        request_id = result.get('request_id', 'unknown')
    
    # Extract answer (handle both dict and SmartAnswer object)
    if isinstance(result, dict):
        answer = result.get('answer', '')
        confidence = result.get('confidence', 0.0)
        sources = result.get('sources', [])
        validation_issues = result.get('validation_issues', [])
    else:
        # SmartAnswer object
        answer = result.answer
        confidence = result.confidence
        sources = result.sources if hasattr(result, 'sources') else []
        validation_issues = result.validation_issues if hasattr(result, 'validation_issues') else []
    
    # DEBUG PRINTS
    print(f"[DEBUG format_slack_response] result type: {type(result)}")
    print(f"[DEBUG format_slack_response] answer length: {len(answer)}")
    print(f"[DEBUG format_slack_response] answer preview: {answer[:100] if answer else 'EMPTY'}")

    # Build Slack blocks
    blocks = []
    
    # ANSWER BLOCK - MUST BE FIRST
    if answer: 
        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": answer
            }
        })
    else:
        print("[DEBUG format_slack_response] WARNING: Answer is empty!")
    
    # Add sources section
    if sources:
        source_lines = []
        for idx, src in enumerate(sources[:3], 1):  # Top 3 sources
            title = src.get('title', f'Source {idx}')
            score = src.get('score', 0.0)
            source_lines.append(f"{idx}. *{title}* (confidence: {score:.2f})")
        
        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "* Sources:*\n" + "\n".join(source_lines)
            }
        })
    
    # Add confidence indicator
    if confidence > 0.8:
        confidence_emoji = "🟢"
        confidence_label = "High"
    elif confidence > 0.5:
        confidence_emoji = "🟡"
        confidence_label = "Medium"
    else:
        confidence_emoji = "🔴"
        confidence_label = "Low"
    
    blocks.append({
        "type": "context",
        "elements": [{
            "type": "mrkdwn",
            "text": f"{confidence_emoji} *Confidence:* {confidence_label} ({confidence:.0%}) | *Request ID:* `{request_id}`"
        }]
    })
    
    # Add validation warnings
    if validation_issues:
        blocks.append({
            "type": "context",
            "elements": [{
                "type": "mrkdwn",
                "text": f"⚠️ *Note:* {len(validation_issues)} validation issue(s) detected"
            }]
        })
    
    return {"blocks": blocks}


def format_json_response(result: Dict[str, Any]) -> Dict[str, Any]:
    """
    Format query result as clean JSON (for REST API).
    
    Args:
        result: Output from process_query()
    
    Returns:
        dict: Clean JSON response with:
            - answer: Main response text
            - confidence: Confidence score
            - sources: Top sources with metadata
            - request_id: For tracing
            - metadata: Additional context
    
    Design:
        - API-friendly format
        - Includes pagination hints for sources
        - Extensible metadata field
    """
    return {
        'success': True,
        'data': {
            'answer': result['answer'],
            'confidence': result['confidence'],
            'sources': [
                {
                    'title': src.get('title', 'Unknown'),
                    'score': src.get('score', 0.0),
                    'url': src.get('url'),
                    'excerpt': src.get('excerpt', '')[:200]  # Truncate long excerpts
                }
                for src in result.get('sources', [])[:3]
            ],
            'request_id': result['request_id']
        },
        'metadata': {
            'total_sources': len(result.get('sources', [])),
            'has_more_sources': len(result.get('sources', [])) > 3,
            'validation_issues': result.get('validation_issues', [])
        }
    }


# ==================== EXPORTS ====================

__all__ = [
    'process_query',
    'format_slack_response',
    'format_json_response'
]