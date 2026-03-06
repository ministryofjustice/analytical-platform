import boto3
import os
import sys
from pathlib import Path
import json
import time
from datetime import datetime
from config import FUNCTION_NAME, REGION
import pytest



@pytest.mark.e2e 
def test_e2e_logging_observability():
    """
    End-to-end test for logging/observability pipeline.
    
    Verifies:
    1. Lambda executes successfully
    2. All pipeline components log correctly
    3. Conversation record is created
    4. Logs appear in CloudWatch with correct structure
    
    Returns:
        bool: True if all validations pass, False otherwise
    """
    
    print("\n" + "="*70)
    print("E2E TEST: Logging & Observability Pipeline")
    print("="*70)
    
    # Test configuration
    test_query = "What is RStudio?"
    expected_components = [
        "slack_event_parsing",
        "query_analyser",
        "retrieval_planner", 
        "filter_generator",
        "bedrock_retrieve",
        "bedrock_generate",
        "lambda_overhead"
    ]
    
    lambda_client = boto3.client('lambda', region_name=REGION)
    logs_client = boto3.client('logs', region_name=REGION)
    log_group = f'/aws/lambda/{FUNCTION_NAME}'
    
    # ==================== STEP 1: Invoke Lambda ====================
    print(f"\n[STEP 1] Invoking Lambda with query: '{test_query}'")
    
    test_event = {
        "body": json.dumps({
            "type": "event_callback",
            "event": {
                "type": "app_mention",
                "text": f"<@U12345> {test_query}",
                "user": "U_E2E_TEST",
                "channel": "C_E2E_TEST"
            }
        })
    }
    
    start_time = time.time()
    
    try:
        response = lambda_client.invoke(
            FunctionName=FUNCTION_NAME,
            InvocationType='RequestResponse',
            Payload=json.dumps(test_event)
        )
        
        duration = time.time() - start_time
        print(f"✓ Lambda responded in {duration:.2f}s")
        
    except Exception as e:
        print(f"✗ Lambda invocation failed: {e}")
        return False
    
    # ==================== STEP 2: Validate Response ====================
    print(f"\n[STEP 2] Validating Lambda response")
    
    try:
        status_code = response['StatusCode']
        payload = json.loads(response['Payload'].read())
        
        # Check Lambda execution succeeded
        if status_code != 200:
            print(f"✗ Lambda returned status {status_code}")
            return False
        print(f"✓ Lambda status: {status_code}")
        
        # Parse response body
        if 'body' not in payload:
            print(f"✗ Response missing 'body' field")
            return False
        
        body = json.loads(payload['body'])
        response_status = payload.get('statusCode', 500)
        
        # Check application-level success
        if response_status != 200:
            print(f"✗ Application returned status {response_status}")
            print(f"  Response: {body}")
            return False
        print(f"✓ Application status: {response_status}")
        
        # Extract request_id from response
        request_id = None
        if 'blocks' in body:
            for block in body['blocks']:
                if block['type'] == 'context':
                    context_text = block['elements'][0]['text']
                    if 'Request ID:' in context_text:
                        request_id = context_text.split('Request ID: `')[1].split('`')[0]
                        break
        
        if not request_id:
            print(f"✗ Could not extract request_id from response")
            return False
        
        print(f"✓ Request ID: {request_id}")
        
        # Validate answer exists
        answer_found = False
        if 'blocks' in body:
            for block in body['blocks']:
                if block['type'] == 'section':
                    answer = block['text']['text']
                    if answer and len(answer) > 10:
                        answer_found = True
                        print(f"✓ Answer received ({len(answer)} chars)")
                        break
        
        if not answer_found:
            print(f"✗ No valid answer in response")
            return False
        
    except Exception as e:
        print(f"✗ Response validation failed: {e}")
        return False
    
    # ==================== STEP 3: Wait for CloudWatch ====================
    print(f"\n[STEP 3] Waiting for logs to appear in CloudWatch")
    print(f"  Waiting 10 seconds...")
    time.sleep(10)
    
    # ==================== STEP 4: Fetch CloudWatch Logs ====================
    print(f"\n[STEP 4] Querying CloudWatch logs for request_id: {request_id}")
    
    try:
        # Query logs from last 60 seconds
        end_time = int(time.time() * 1000)
        start_log_time = int((time.time() - 60) * 1000)
        
        response = logs_client.filter_log_events(
            logGroupName=log_group,
            startTime=start_log_time,
            endTime=end_time,
            limit=100  # Get more logs to ensure we capture everything
        )
        
        events = response.get('events', [])
        
        if not events:
            print(f"✗ No logs found in CloudWatch")
            print(f"  Check manually: https://console.aws.amazon.com/cloudwatch/home?region={REGION}#logsV2:log-groups/log-group/{log_group.replace('/', '$252F')}")
            return False
        
        print(f"✓ Found {len(events)} log entries")
        
    except Exception as e:
        print(f"✗ Failed to fetch CloudWatch logs: {e}")
        return False
    
    # ==================== STEP 5: Parse and Filter Logs ====================
    print(f"\n[STEP 5] Filtering logs for request_id: {request_id}")
    
    request_logs = []
    
    for event in events:
        message = event['message'].strip()
        
        # Skip AWS internal logs
        if message.startswith('START') or message.startswith('END') or message.startswith('REPORT'):
            continue
        
        try:
            log_data = json.loads(message)
            
            # Filter by request_id
            if log_data.get('request_id') == request_id:
                request_logs.append(log_data)
        
        except json.JSONDecodeError:
            # Skip non-JSON logs
            continue
    
    if not request_logs:
        print(f"✗ No logs found for request_id: {request_id}")
        print(f"  Total events checked: {len(events)}")
        return False
    
    print(f"✓ Found {len(request_logs)} logs for this request")
    
    # ==================== STEP 6: Validate Log Structure ====================
    print(f"\n[STEP 6] Validating log structure and content")
    
    validations = {
        "request_start": False,
        "components_logged": [],
        "request_success": False,
        "conversation_complete": False
    }
    
    for log in request_logs:
        log_type = log.get('log_type')
        
        # Check for request_start
        if log_type == 'request_start':
            validations['request_start'] = True
            if log.get('query') != test_query:
                print(f"✗ Query mismatch in request_start")
                print(f"  Expected: '{test_query}'")
                print(f"  Got: '{log.get('query')}'")
                return False
        
        # Check for component logs
        elif log_type == 'component':
            component = log.get('component_name')
            duration = log.get('duration_ms')
            
            if component:
                validations['components_logged'].append(component)
            
            # Validate duration is reasonable
            if duration is None or duration < 0:
                print(f"✗ Invalid duration for {component}: {duration}")
                return False
        
        # Check for request_success
        elif log_type == 'request_success':
            validations['request_success'] = True
            
            # Validate metrics exist
            metrics = log.get('metrics', {})
            if not metrics:
                print(f"✗ request_success missing metrics")
                return False
            
            # Validate confidence
            confidence = metrics.get('confidence')
            if confidence is None or not (0 <= confidence <= 1):
                print(f"✗ Invalid confidence value: {confidence}")
                return False
        
        # Check for conversation_complete
        elif log_type == 'conversation_complete':
            validations['conversation_complete'] = True
            
            # Validate conversation record structure
            if not log.get('success'):
                print(f"✗ Conversation marked as failed")
                return False
            
            if log.get('query') != test_query:
                print(f"✗ Query mismatch in conversation_complete")
                return False
            
            total_logs = log.get('total_logs', 0)
            if total_logs < 5:  # Should have at least start + components + success + conversation
                print(f"✗ Too few logs in conversation record: {total_logs}")
                return False
    
    # ==================== STEP 7: Validate All Components Logged ====================
    print(f"\n[STEP 7] Checking all components logged")
    
    if not validations['request_start']:
        print(f"✗ Missing request_start log")
        return False
    print(f"✓ request_start logged")
    
    if not validations['request_success']:
        print(f"✗ Missing request_success log")
        return False
    print(f"✓ request_success logged")
    
    if not validations['conversation_complete']:
        print(f"✗ Missing conversation_complete log")
        return False
    print(f"✓ conversation_complete logged")
    
    # Check all expected components
    missing_components = []
    for component in expected_components:
        if component not in validations['components_logged']:
            missing_components.append(component)
    
    if missing_components:
        print(f"✗ Missing component logs: {', '.join(missing_components)}")
        print(f"  Components found: {', '.join(validations['components_logged'])}")
        return False
    
    print(f"✓ All {len(expected_components)} components logged:")
    for component in validations['components_logged']:
        print(f"  - {component}")
    
    # ==================== STEP 8: Success Summary ====================
    print(f"\n" + "="*70)
    print("✅ ALL VALIDATIONS PASSED")
    print("="*70)
    print(f"\nTest Summary:")
    print(f"  Query: '{test_query}'")
    print(f"  Request ID: {request_id}")
    print(f"  Lambda Duration: {duration:.2f}s")
    print(f"  Total Logs: {len(request_logs)}")
    print(f"  Components Logged: {len(validations['components_logged'])}")
    print(f"\nCloudWatch Logs:")
    print(f"  https://console.aws.amazon.com/cloudwatch/home?region={REGION}#logsV2:log-groups/log-group/{log_group.replace('/', '$252F')}")
    print(f"\nQuery by request_id:")
    print(f'  fields @timestamp, @message')
    print(f'  | filter request_id = "{request_id}"')
    print(f'  | sort @timestamp desc')
    
    return True


# ==================== Run Test ====================
if __name__ == "__main__":
    success = test_e2e_logging_observability()
    
    if success:
        print("\n✅ E2E test PASSED")
        exit(0)
    else:
        print("\n❌ E2E test FAILED")
        exit(1)