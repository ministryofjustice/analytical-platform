"""
Query utilities for DynamoDB conversation logs

DynamoDB query helper module with 4 functins:

1) get_table() Returns DynamoDB table resource
2) get_Session_history(session_id)
    - Uses SessionIndex GSI
    - Returns all Q&A pairs in chronological order
    - For conversation continuity

3) get_user_history(user_id, limit=50)
    - User UserTimeIndex GSI
    - Returns recent Q&A pairs(newest first)
    - For user analytics/history view

4) get_conversation_by_id(request_id)
    - Primary key query
    - REturns single Q&A item
    - Needed for feedback updates(to get timestamp)

5) update_feedback(request_id, feedback, timestamp)
    - Gets item first ( to retrieve timestamp sort key)
    - Updates user_feedback(positive/negative) and feedback_timestamp
    - Returns success/failure 

    
"""
# dynamodb_query_utils.py
import os
import sys
from pathlib import Path
import boto3
from typing import List, Dict, Any, Optional
from botocore.exceptions import ClientError

#sys.path.insert(0, str(Path(__file__).parent.parent.parent))
#from config import DYNAMODB_TABLE_NAME
table_name = os.environ.get('DYNAMODB_TABLE_NAME')


def get_table():
    """Get DynamoDB table resource"""
    #table_name = table_name or os.getenv('DYNAMODB_TABLE_NAME', 'RAG-ConversationLogs')
    dynamodb = boto3.resource('dynamodb')
    return dynamodb.Table(table_name)


def get_session_history(session_id: str) -> List[Dict[str, Any]]:
    """
    Get all Q&A pairs from a session (chronological order)
    
    Returns list of items sorted by timestamp
    """
    try:
        table = get_table()
        response = table.query(
            IndexName='SessionIndex',
            KeyConditionExpression=boto3.dynamodb.conditions.Key('session_id').eq(session_id),
            ScanIndexForward=True  # Chronological order
        )
        return response['Items']
    except ClientError as e:
        print(f"❌ Query failed: {e}")
        return []


def get_user_history(user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
    """
    Get recent Q&A pairs for a user (newest first)
    """
    try:
        table = get_table()
        response = table.query(
            IndexName='UserTimeIndex',
            KeyConditionExpression=boto3.dynamodb.conditions.Key('user_id').eq(user_id),
            Limit=limit,
            ScanIndexForward=False  # Newest first
        )
        return response['Items']
    except ClientError as e:
        print(f"❌ Query failed: {e}")
        return []


def get_conversation_by_id(request_id: str) -> Optional[Dict[str, Any]]:
    """Get specific Q&A by request_id"""
    try:
        table = get_table()
        response = table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key('request_id').eq(request_id),
            Limit=1
        )
        items = response.get('Items', [])
        return items[0] if items else None
    except ClientError as e:
        print(f"❌ Get failed: {e}")
        return None


def update_feedback(request_id: str, feedback: str, timestamp: str, comment: str = None) -> bool:
    """
    Update feedback for a Q&A
    
    Args:
        request_id: Question ID
        feedback: 'positive' or 'negative'
        timestamp: ISO timestamp of feedback
    """
    try:
        table = get_table()
        
        # Get the item first to get its timestamp (sort key)
        item = get_conversation_by_id(request_id)
        if not item:
            print(f"❌ Request ID not found: {request_id}")
            return False
        
        # Update with both keys
        table.update_item(
            Key={
                'request_id': request_id,
                'timestamp': item['timestamp']
            },
            UpdateExpression='SET user_feedback = :feedback, feedback_timestamp = :ts, feedback_comment = :comment',
            ExpressionAttributeValues={
                ':feedback': feedback,
                ':ts': timestamp
            }
        )
        print(f"✅ Feedback updated: {request_id} = {feedback}")
        return True
        
    except ClientError as e:
        print(f"❌ Update failed: {e}")
        return False