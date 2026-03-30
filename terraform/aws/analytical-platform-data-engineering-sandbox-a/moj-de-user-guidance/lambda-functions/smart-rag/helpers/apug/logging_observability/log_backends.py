# log_backends.py

""" 
- Defines an abstract LogBackend interface for pluggable log storage.
- Includes three backend implementations:
    - CloudWatchBackend
        - Outputs logs as single-line JSON for AWS Lambda (or pretty JSON when local).
        - Emits conversation summaries at the end of each request.
    - DynamoDBBackend
        - Placeholder for future persistence of full conversation records.
    - S3Backend
        - Placeholder for future batched JSONL log storage in S3.
- Provides methods for writing individual logs, conversation-level logs, and flushing buffered data.

"""


import os
import json
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional

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
    
    def write_log(self, log_data: Dict[str, Any]):
        """Write single log entry"""
        if self.environment == "local":
            # Pretty print for console debugging
            print(json.dumps(log_data, indent=2))
        else:
            # Single-line JSON for CloudWatch Logs Insights
            print(json.dumps(log_data))
    
    def write_conversation(self, conversation_data: Dict[str, Any]):
        """
        Write complete conversation record with all logs and metrics.
        
        This creates a single comprehensive log entry for:
        - End-to-end request tracking
        - CloudWatch Insights queries
        - Future export to DynamoDB/S3
        """
        # Build full conversation record
        conversation_record = {
            "log_type": "conversation_complete",
            "environment": self.environment,
            **conversation_data  # Includes: request_id, query, success, logs[], metrics, etc.
        }
        
        # Write as single JSON line (CloudWatch Logs Insights can parse this)
        print(json.dumps(conversation_record))
    
    def flush(self):
        """No buffering needed for stdout"""
        pass


class DynamoDBBackend(LogBackend):
    """Writes conversation records to DynamoDB (implement later)"""
    
    def __init__(self, table_name: str = None):
        self.table_name = table_name or os.environ.get('DYNAMODB_TABLE_NAME')
        # TODO: Initialize boto3 DynamoDB client
        #   import boto3
        #   self.dynamodb = boto3.resource('dynamodb')
        #   self.table = self.dynamodb.Table(self.table_name)
    
    def write_log(self, log_data: Dict[str, Any]):
        """DynamoDB only stores conversation summaries, not individual logs"""
        pass
    
    def write_conversation(self, conversation_data: Dict[str, Any]):
        """Write complete conversation to DynamoDB"""
        # TODO: Implement
        #   import time
        #   self.table.put_item(Item={
        #       'request_id': conversation_data['request_id'],
        #       'timestamp': conversation_data['timestamp'],
        #       'query': conversation_data['query'],
        #       'success': conversation_data['success'],
        #       'confidence': conversation_data.get('confidence', 0.0),
        #       'answer': conversation_data.get('answer', ''),
        #       'logs': json.dumps(conversation_data['logs']),  # Store as JSON string
        #       'ttl': int(time.time()) + 30*24*60*60  # 30 days retention
        #   })
        pass
    
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
        #   self.buffer.append(log_data)
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