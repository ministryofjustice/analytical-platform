# log_backends.py

""" 
- Defines an abstract LogBackend interface for pluggable log storage.

- Abstract base class LogBackend with 3 methods: write_log(), write_conversation(), flush()
- Includes three backend implementations:
    - CloudWatchBackend
        - Outputs logs as single-line JSON for AWS Lambda (or pretty JSON when local) to stdout
        - Smart filtering (critical logs, errors, DEBUG mode)
        - Separate summary for success/failure cases
    - DynamoDBBackend
        - Verfies table on init
        - Stores: request_id, timestamp, user_id, session_id, answer, success, duration_ms, etc.
        - Adds TTL(90 days)
        - Handles success vs failure cases
        - Has feedback placeholders (user_feedback, feedback_timestamp)
        - Error handling (doesn't break requests if DynamoDB fails)
    - S3Backend
        - Placeholder for future batched JSONL log storage in S3.
- Provides methods for writing individual logs, conversation-level logs, and flushing buffered data.
- Factory function get_log_backends() checks env vars:
    - DYNAMODB_LOG_TABLE → adds DynamoDB
    - S3_LOG_BUCKET → adds S3



SmartRAGLogger (orchestrator)
    ↓
LogBackend Interface (abstraction)
    ├── CloudWatchBackend (stdout → Lambda → CloudWatch)
    ├── DynamoDBBackend (conversation history - TODO)
    └── S3Backend (analytics archive - TODO)

Multi-layer logging:

Layer 1: Component-level logs (query_analyser, bedrock_retrieve, etc.)
Layer 2: Conversation-level summaries
Layer 3: CloudWatch Insights queryable logs

"""


import os
import sys
import time
import boto3
import json
import logging
from pathlib import Path
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from config import DYNAMODB_TABLE_NAME
table_name = DYNAMODB_TABLE_NAME

class LogBackend(ABC):
    """Interface for log storage backends"""
    
    @abstractmethod
    def write_log(self, log_data: Dict[str, Any]):
        """Write individual log entry"""
        pass
    
    @abstractmethod
    def write_conversation(self, conversation_data: Dict[str, Any]):
        """Write complete conversation record (called at end)"""
        pass
    
    @abstractmethod
    def flush(self):
        """Flush any buffered data"""
        pass


# ==================== Infrastructure Backends ====================

class CloudWatchBackend(LogBackend):
    """Writes logs to stdout (captured by CloudWatch in Lambda)"""
    
    def __init__(self):
        # Detect environment
        self.environment = "lambda" if os.environ.get("AWS_LAMBDA_FUNCTION_NAME") else "local"

        # Get or create logger
        self.logger = logging.getLogger() #This makes Lambda's root logger and CloudWatch backend use the same stream.

        # Only configure if not already configured
        if not self.logger.handlers:
            self.logger.setLevel(logging.INFO)
            
            # Create console handler
            handler = logging.StreamHandler(sys.stdout)
            handler.setLevel(logging.INFO)
            
            # Format: plain JSON (no extra formatting for CloudWatch Insights)
            formatter = logging.Formatter('%(message)s')
            handler.setFormatter(formatter)
            
            self.logger.addHandler(handler)
            self.logger.propagate = False  # Don't propagate to root logger
    
    def write_log(self, log_data: Dict[str, Any]):
        """Smart filtering based on environment"""
        
        log_level = os.environ.get("LOG_LEVEL", "INFO")
        log_type = log_data.get("log_type")
        level = log_data.get("level")
        
        # Always log critical events
        critical_logs = ['request_start', 'request_success', 'request_error']
        
        should_log = (
            log_type in critical_logs or
            level == "ERROR" or
            log_level == "DEBUG"
        )
        
        if not should_log:
            return
        
        # Write to stdout
        print(json.dumps(log_data))
    
    def write_conversation(self, conversation_data: Dict[str, Any]):
        """Write summary with failure diagnostics"""
        
        success = conversation_data.get("success", False)
        logs = conversation_data.get("logs", [])
        
        summary = {
            "log_type": "conversation_complete",
            "request_id": conversation_data["request_id"],
            "timestamp": conversation_data["timestamp"],
            "query": conversation_data["query"][:200],
            "success": success
        }
        
        if success:
            summary.update({
                "total_duration_ms": sum(log.get("duration_ms", 0) for log in logs),
                "confidence": conversation_data.get("confidence"),
                "answer_length": len(conversation_data.get("answer", ""))
            })
        else:
            # Failure diagnostics
            component_logs = [log for log in logs if log.get("log_type") == "component"]
            error_log = next((log for log in logs if log.get("log_type") == "request_error"), None)
            
            summary.update({
                "error_type": error_log.get("error_type") if error_log else "Unknown",
                "error_message": error_log.get("error_message") if error_log else "Unknown",
                "failed_component": error_log.get("failed_component") if error_log else "Unknown",
                "completed_components": [
                    {"name": log["component_name"], "duration_ms": log["duration_ms"]}
                    for log in component_logs
                ],
                "duration_before_failure_ms": sum(log.get("duration_ms", 0) for log in component_logs)
            })
        
        print(json.dumps(summary))

    def flush(self):
        """No buffering needed for stdout"""
        #pass
        for handler in self.logger.handlers:
            handler.flush()


class DynamoDBBackend(LogBackend):
    """Writes conversation records to DynamoDB (implement later)"""
    
    def __init__(self, table_name: str = None):
        self.table_name = table_name or os.environ.get('DYNAMODB_TABLE_NAME')
        self._table_verified = False

        if not self.table_name:
            print("⚠️  DYNAMODB_TABLE_NAME not set - skipping DynamoDB logging")
            return
        
        try:
            self.dynamodb = boto3.resource('dynamodb')
            self.table = self.dynamodb.Table(self.table_name)
            self.table.load()  # Verify table exists
            self._table_verified = True
            print(f"✅ DynamoDB backend ready: {self.table_name}")
        except Exception as e:
            print(f"⚠️  DynamoDB init failed: {e}")

    
    def write_log(self, log_data: Dict[str, Any]):
        """DynamoDB only stores conversation summaries, not individual logs"""
        pass
    
    def write_conversation(self, conversation_data: Dict[str, Any]):
        """Write complete conversation to DynamoDB"""
        if not self._table_verified:
            return
        
        try:
            # Base item
            item = {
                # Primary keys
                'request_id': conversation_data['request_id'],
                'timestamp': conversation_data['timestamp'],
                
                # User context (required for GSIs)
                'user_id': conversation_data.get('user_id', 'anonymous'),
                'session_id': conversation_data.get('session_id', conversation_data['request_id']),
                
                # Q&A content
                'query': conversation_data['query'][:1000],
                'success': conversation_data.get('success', False),
                
                # Metadata
                'ttl': int(time.time()) + (90 * 24 * 60 * 60),
                'environment': os.environ.get('ENVIRONMENT', 'dev'),
                
                # Feedback placeholders (updated later)
                'user_feedback': None,  # 'positive' | 'negative' | None
                'feedback_timestamp': None
            }
            
            # Success fields
            if conversation_data.get('success'):
                item.update({
                    'answer': conversation_data.get('answer', '')[:5000],
                    'confidence': float(conversation_data.get('confidence', 0.0)),
                    'duration_ms': int(conversation_data.get('duration_ms', 0)),
                    'answer_length': len(conversation_data.get('answer', ''))
                })
                
                # Component execution summary
                component_logs = [
                    {'name': log.get('component_name'), 'duration_ms': log.get('duration_ms')}
                    for log in conversation_data.get('logs', [])
                    if log.get('log_type') == 'component'
                ]
                if component_logs:
                    item['components'] = json.dumps(component_logs)
            
            # Failure fields
            else:
                error_log = next(
                    (log for log in conversation_data.get('logs', []) 
                     if log.get('log_type') == 'request_error'),
                    {}
                )
                item['error_type'] = error_log.get('error_type', 'Unknown')
                item['error_message'] = error_log.get('error_message', '')[:500]
                item['answer'] = None
            
            # Write to DynamoDB
            self.table.put_item(Item=item)
            print(f"✅ Logged to DynamoDB: {item['request_id']}")
            
        except Exception as e:
            print(f"❌ DynamoDB write failed: {e}")
            # Don't raise - logging shouldn't break requests
    
    
    def flush(self):
        """No buffering in current design"""
        pass


class S3Backend(LogBackend):
    """Writes logs to S3 for analytics (implement post-POC)"""
    
    def __init__(self, bucket: str = None, prefix: str = "rag-logs"):
        self.bucket = bucket or os.environ.get('S3_LOG_BUCKET')
        self.prefix = prefix
        self.buffer = []  # Buffer logs for batch write
    
    def write_log(self, log_data: Dict[str, Any]):
        """Buffer individual component logs"""
        # TODO: Store in buffer for batch write
        #   self.buffer.append(log_data) # List append is NOT thread-safe - consider using a thread-safe queue if needed
        pass
    
    def write_conversation(self, conversation_data: Dict[str, Any]):
        """Buffer conversation summary for S3"""
        # TODO: Add conversation to buffer
        #   self.buffer.append({
        #       **conversation_data,
        #       "log_type": "conversation_complete"
        #   })
        pass
    
    def flush(self):
        """Write buffered logs to S3 in JSON Lines format"""
        # TODO: Implement S3 batch write
        #   if not self.buffer:
        #       return
        #   
        #   import boto3
        #   import uuid
        #   from datetime import datetime
        #   
        #   s3 = boto3.client('s3')
        #   timestamp = datetime.utcnow().strftime('%Y/%m/%d/%H')
        #   key = f"{self.prefix}/{timestamp}/{uuid.uuid4()}.jsonl"
        #   
        #   # Write as JSON Lines format (one JSON per line)
        #   content = '\n'.join([json.dumps(log) for log in self.buffer])
        #   s3.put_object(
        #       Bucket=self.bucket, 
        #       Key=key, 
        #       Body=content,
        #       ContentType='application/x-ndjson'
        #   )
        #   
        #   print(f"[S3Backend] Flushed {len(self.buffer)} logs to s3://{self.bucket}/{key}")
        #   self.buffer.clear()
        pass

########

# ==================== Backend Factory ====================
def get_log_backends():
    """Return appropriate log backends based on environment."""
    import os
    
    backends = [CloudWatchBackend()]  # Always include CloudWatch
    
    # Optional: DynamoDB for queryable conversation history
    if os.environ.get("DYNAMODB_LOG_TABLE"):
        backends.append(DynamoDBBackend(
            table_name = table_name
        ))
    
    # Optional: S3 for long-term analytics
    if os.environ.get("S3_LOG_BUCKET"):
        backends.append(S3Backend(
            bucket=os.environ.get("S3_LOG_BUCKET"),
            prefix="rag-logs"
        ))
    
    return backends