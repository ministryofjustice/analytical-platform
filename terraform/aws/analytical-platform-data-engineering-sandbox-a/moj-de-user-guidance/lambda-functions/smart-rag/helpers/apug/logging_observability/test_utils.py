"""
Lambda Testing Utilities

Provides helper functions for testing the Smart RAG chatbot Lambda function
with Slack-formatted events and displaying CloudWatch logs.

Functions:
    test_question(question: str) -> str
        Invokes Lambda with a test question, displays the response,
        fetches CloudWatch logs, and returns the request_id.

Usage:
    from helpers.apug.logging_observability.test_utils import test_question
    
    # Test a single question
    request_id = test_question("What is RStudio?")
    
    # Use request_id to query specific logs in CloudWatch

Example Output:
    ================================================================================
    QUESTION: What is RStudio?
    ================================================================================
    
    ANSWER:
    RStudio is an integrated development environment (IDE) for R...
    
    Response Time: 4.52s
    Request ID: abc-123-def-456
    Confidence: 0.92 | Citations: 5 | Retrieved: 3.2s
    
    --------------------------------------------------------------------------------
    EXECUTION TRACE
    --------------------------------------------------------------------------------
    ▶️  START
       └─ query_analyser              245ms
       └─ retrieval_planner           150ms
       └─ filter_gen                  300ms
       └─ bedrock_retrieval          3200ms
    ✅ SUCCESS - Confidence: 0.92 - Total: 3450ms
    ✓  Logged 12 events
    
    ================================================================================

Notes:
    - Requires AWS credentials configured (boto3 access)
    - Lambda function must be deployed before testing
    - CloudWatch logs appear after ~3 second delay
    - Function constructs Slack-formatted test events automatically

Dependencies:
    - boto3: AWS SDK for Lambda invocation and CloudWatch log fetching
    - config: FUNCTION_NAME and REGION constants

"""

import boto3
import json
import time
from config import FUNCTION_NAME, REGION

# Test Function
def test_question(question):
    """Test Lambda with a question and display detailed results"""
    
    print("="*80)
    print(f"QUESTION: {question}")
    print("="*80)
    
    # Build test event
    test_event = {
        "body": json.dumps({
            "type": "event_callback",
            "event": {
                "type": "app_mention",
                "text": f"<@U12345> {question}",
                "user": "U_DEMO_USER",
                "channel": "C_DEMO_CHANNEL"
            }
        })
    }
    
    # Invoke Lambda
    lambda_client = boto3.client('lambda', region_name=REGION)
    start_time = time.time()
    
    response = lambda_client.invoke(
        FunctionName=FUNCTION_NAME,
        InvocationType='RequestResponse',
        Payload=json.dumps(test_event)
    )
    
    duration = time.time() - start_time
    payload = json.loads(response['Payload'].read())
    
    # Parse Response
    body = json.loads(payload['body'])
    request_id = None
    answer = ""
    metadata = ""
    
    for block in body.get('blocks', []):
        if block['type'] == 'section':
            answer = block['text']['text']
        elif block['type'] == 'context':
            metadata = block['elements'][0]['text']
            if 'Request ID:' in metadata:
                request_id = metadata.split('Request ID: `')[1].split('`')[0]
    
    # Display Answer
    print(f"\n ANSWER:\n{answer}\n")
    print(f"  Response Time: {duration:.2f}s")
    print(f" Request ID: {request_id}")
    print(f" {metadata}\n")
    
    # Fetch and Display Logs
    time.sleep(3)
    
    print("-"*80)
    print("EXECUTION TRACE")
    print("-"*80)
    
    logs_client = boto3.client('logs', region_name=REGION)
    log_group = f"/aws/lambda/{FUNCTION_NAME}"
    
    log_response = logs_client.filter_log_events(
        logGroupName=log_group,
        startTime=int((time.time() - 30) * 1000),
        endTime=int(time.time() * 1000),
        limit=25
    )
    
    for event in log_response.get('events', []):
        try:
            log_data = json.loads(event['message'].strip())
            log_type = log_data.get('log_type', '')
            
            if log_type == 'request_start':
                print(f"  START")
            elif log_type == 'component':
                comp = log_data['component_name']
                dur = log_data['duration_ms']
                print(f"   └─ {comp:25s} {dur:7.0f}ms")
            elif log_type == 'request_success':
                conf = log_data['metrics']['confidence']
                total = log_data['total_duration_ms']
                print(f"✅ SUCCESS - Confidence: {conf:.2f} - Total: {total:.0f}ms")
            elif log_type == 'conversation_complete':
                print(f"✓  Logged {log_data['total_logs']} events")
            elif log_data.get('level') == 'ERROR':
                print(f"❌ ERROR: {log_data.get('error_message', '')}")
        except json.JSONDecodeError:
            pass
    
    print("\n" + "="*80 + "\n")

