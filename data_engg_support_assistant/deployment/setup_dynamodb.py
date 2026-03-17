"""
DynamoDB Table Setup for RAG Conversation Logging

This script creates and configures a DynamoDB table to store conversation logs
from the RAG chatbot, including queries, answers, performance metrics, and user feedback.

Table Schema:
    - Primary Key: request_id (HASH) + timestamp (RANGE)
    - GSIs: UserTimeIndex, SessionIndex
    - TTL: 90 days automatic expiration
    - Features: Point-in-Time Recovery, Streams enabled

Usage:
    python deployment/setup_dynamodb.py

Environment Variables:
    DYNAMODB_TABLE_NAME (optional): Custom table name (default: RAG-ConversationLogs)
    AWS_REGION (optional): AWS region (default: eu-west-2)

Post-Setup:
    1. Update Lambda environment: DYNAMODB_TABLE_NAME=RAG-ConversationLogs
    2. Add IAM permissions: PutItem, UpdateItem, GetItem, Query
    3. Implement DynamoDBBackend.write_conversation() in log_backends.py
    4. Deploy and test

The sequence is now:

    - Create table
    - Wait for ACTIVE status
    - Enable Point-in-Time Recovery (PITR)
    - Enable TTL
    - Enable Streams (if you have that after)

"""
# deployment/setup_dynamodb.py

import boto3
import os
import sys
from botocore.exceptions import ClientError
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import REGION

# Configuration
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME', 'RAG-ConversationLogs')
REGION = os.environ.get('AWS_REGION', 'eu-west-2')

def create_conversation_logs_table(
    table_name: str = TABLE_NAME,
    region: str = REGION
):
    """
    Create DynamoDB table for RAG conversation logging
    
    Schema Design:
    - PK: request_id (unique per API call)
    - SK: timestamp (ISO format for time-based queries)
    - GSIs: UserTimeIndex, SessionIndex only (optimized for common queries)
    - TTL: 90 days retention for compliance/analytics
    """
    
    dynamodb = boto3.client('dynamodb', region_name=region)
    
    print(f"Creating DynamoDB table: {table_name}")
    
    try:
        response = dynamodb.create_table(
            TableName=table_name,
            
            # Primary Key Schema
            KeySchema=[
                {'AttributeName': 'request_id','KeyType': 'HASH' }, # Partition key
                {'AttributeName': 'timestamp', 'KeyType': 'RANGE'}  # Sort key
            ],
            
            # Attribute Definitions (only for keys and GSI)
            # Note: Other attributes (query, answer, duration_ms, etc.) 
            # are dynamically added per item - no need to define here
            AttributeDefinitions=[
                {'AttributeName': 'request_id', 'AttributeType': 'S'},
                {'AttributeName': 'timestamp', 'AttributeType': 'S'},
                {'AttributeName': 'user_id', 'AttributeType': 'S'},
                {'AttributeName': 'session_id', 'AttributeType': 'S'}
            ],
            
            # Global Secondary Indexes 
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'UserTimeIndex',
                    'KeySchema': [
                        {'AttributeName': 'user_id', 'KeyType': 'HASH'},
                        {'AttributeName': 'timestamp', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {
                        'ProjectionType': 'ALL'  # Include all attributes
                    }
                },
                {
                    'IndexName': 'SessionIndex',
                    'KeySchema': [
                        {'AttributeName': 'session_id', 'KeyType': 'HASH'},
                        {'AttributeName': 'timestamp', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {
                        'ProjectionType': 'ALL'
                    }
                }
            ],
            
            # Billing Mode
            BillingMode='PAY_PER_REQUEST',  # On-demand pricing for POC
            
            # Tags
            Tags=[
                {'Key': 'Environment', 'Value': os.environ.get('ENVIRONMENT', 'dev')},
                {'Key': 'Application', 'Value': 'RAG-Chatbot'},
                {'Key': 'Purpose', 'Value': 'ConversationLogging'},
                {'Key': 'CostCenter', 'Value': 'DataEngineering'},
                {'Key': 'ManagedBy', 'Value': 'Terraform'}
            ]
        )
        
        print(f"✅ Table creation initiated: {table_name}")
        print(f"   Status: {response['TableDescription']['TableStatus']}")
        
        # Wait for table to be active
        print(" Waiting for table to become active...")
        waiter = dynamodb.get_waiter('table_exists')
        waiter.wait(
            TableName=table_name,
            WaiterConfig={'Delay': 5, 'MaxAttempts': 20}
        )
        
        print("✅ Table is now ACTIVE")

        # Enable Point-in-Time Recovery (separate API call)
        print(" Enabling Point-in-Time Recovery...")
        dynamodb.update_continuous_backups(
            TableName=table_name,
            PointInTimeRecoverySpecification={
                'PointInTimeRecoveryEnabled': True
            }
        )
        print("✅ Point-in-Time Recovery enabled")

        # Enable TTL (90 days retention)
        print(" Enabling TTL for automatic data expiration...")
        dynamodb.update_time_to_live(
            TableName=table_name,
            TimeToLiveSpecification={'Enabled': True,'AttributeName': 'ttl'}
        )
        print("✅ TTL enabled on 'ttl' attribute (90-day retention)")
        
        # Enable Streams (optional - for future real-time analytics/triggers)
        print(" Enabling DynamoDB Streams...")
        dynamodb.update_table(
            TableName=table_name,
            StreamSpecification={
                'StreamEnabled': True,
                'StreamViewType': 'NEW_AND_OLD_IMAGES'  # Capture before/after states
            }
        )
        print("✅ DynamoDB Streams enabled")
        
        return response
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        
        if error_code == 'ResourceInUseException':
            print(f"⚠️  Table '{table_name}' already exists")
            return None
        elif error_code == 'LimitExceededException':
            print(f"❌ AWS account table limit reached")
            sys.exit(1)
        else:
            print(f"❌ Error creating table: {e}")
            sys.exit(1)


def verify_table_setup(table_name: str, region: str = REGION):
    """Verify table was created with correct configuration"""
    
    dynamodb = boto3.client('dynamodb', region_name=region)
    
    try:
        response = dynamodb.describe_table(TableName=table_name)
        table = response['Table']
        
        print(f"\n Table Configuration Summary:")
        print(f"   Table Name: {table['TableName']}")
        print(f"   Status: {table['TableStatus']}")
        print(f"   Item Count: {table['ItemCount']}")
        print(f"   Size (bytes): {table['TableSizeBytes']}")
        print(f"   GSIs: {len(table.get('GlobalSecondaryIndexes', []))}")
        
        # Check TTL
        ttl_response = dynamodb.describe_time_to_live(TableName=table_name)
        ttl_status = ttl_response['TimeToLiveDescription']['TimeToLiveStatus']
        print(f"   TTL Status: {ttl_status}")
        
        # Check Streams
        stream_enabled = table.get('StreamSpecification', {}).get('StreamEnabled', False)
        print(f"   Streams: {'Enabled' if stream_enabled else 'Disabled'}")
        
        print("\n✅ Table verification complete")
        
    except ClientError as e:
        print(f"❌ Error verifying table: {e}")
        sys.exit(1)

def delete_table(table_name: str, region: str = REGION):
    """Delete table (use with caution!)"""
    
    dynamodb = boto3.client('dynamodb', region_name=region)
    
    confirmation = input(f"⚠️  Are you sure you want to delete '{table_name}'? (yes/no): ")
    if confirmation.lower() != 'yes':
        print("Aborted")
        return
    
    try:
        dynamodb.delete_table(TableName=table_name)
        print(f"✅ Table '{table_name}' deleted")
    except ClientError as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='DynamoDB Table Management')
    parser.add_argument('action', choices=['create', 'verify', 'delete'], help='Action to perform')
    parser.add_argument('--table-name', default=TABLE_NAME, help='Table name')
    parser.add_argument('--region', default=REGION, help='AWS region')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("DynamoDB Table Setup for RAG Conversation Logging")
    print("=" * 60)

    if args.action == 'create':
        result = create_conversation_logs_table(args.table_name, args.region)
        if result:
            verify_table_setup(args.table_name, args.region)
            print("\n Next Steps:")
            print(f"1. Set Lambda env var: DYNAMODB_TABLE_NAME={args.table_name}")
            print("2. Add IAM permissions: dynamodb:PutItem, dynamodb:Query, dynamodb:GetItem")
            print("3. Deploy updated code")
    
    elif args.action == 'verify':
        verify_table_setup(args.table_name, args.region)
    
    elif args.action == 'delete':
        delete_table(args.table_name, args.region)

