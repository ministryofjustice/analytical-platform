# fix_lambda_config.py
"""
Manually update Lambda environment variables without redeploying code.
Use when testing different MODEL_IDs, regions, or token limits.
"""
import boto3
from config import KB_ID, MODEL_ID, REGION, MAX_CONTEXT_TOKENS, FUNCTION_NAME

lambda_client = boto3.client('lambda', region_name=REGION)

lambda_client.update_function_configuration(
    FunctionName=FUNCTION_NAME,
    Timeout=60,
    MemorySize=512,
    Environment={
        'Variables': {
            'KB_ID': KB_ID,
            'MODEL_ID': MODEL_ID,
            'BEDROCK_REGION': REGION,
            'MAX_CONTEXT_TOKENS': str(MAX_CONTEXT_TOKENS)
        }
    }
)
print("✅ Configuration updated!")