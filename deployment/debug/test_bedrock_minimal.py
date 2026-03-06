# test_bedrock_minimal.py
"""
Minimal Lambda function to test if Bedrock access works (isolates IAM issues).
Deploy as separate Lambda, invoke, check CloudWatch logs for AccessDenied errors.
"""
import boto3
import json
import os

def lambda_handler(event, context):
    """Minimal test - just call Bedrock"""
    
    MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"
    REGION = "eu-west-2"
    
    print(f" Testing Bedrock from Lambda")
    print(f"   Model: {MODEL_ID}")
    print(f"   Region: {REGION}")
    print(f"   Lambda Role: {os.environ.get('AWS_EXECUTION_ENV', 'Unknown')}")
    
    bedrock = boto3.client('bedrock-runtime', region_name=REGION)
    
    try:
        print("\n Calling Bedrock...")
        
        response = bedrock.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 50,
                "messages": [{"role": "user", "content": "Say 'test successful' in 3 words"}],
                "temperature": 0.0
            })
        )
        
        print(" Bedrock call succeeded!")
        result = json.loads(response['body'].read())
        text = result['content'][0]['text']
        print(f" Response: {text}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({'success': True, 'response': text})
        }
        
    except bedrock.exceptions.AccessDeniedException as e:
        print(f" Error: ACCESS DENIED: {e}")
        return {
            'statusCode': 403,
            'body': json.dumps({
                'error': 'AccessDenied',
                'message': str(e),
                'hint': 'IAM role needs bedrock:InvokeModel permission'
            })
        }
    except Exception as e:
        print(f" Error: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

if __name__ == "__main__":
    result = lambda_handler({}, None)
    print(json.dumps(result, indent=2))