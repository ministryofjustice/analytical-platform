"""
deploy_api_gateway.py - API Gateway utilities for Terraform-managed infrastructure

Terraform manages:
- REST API creation
- Resources, methods, integrations
- Authorizer configuration
- Lambda permissions
- Stage deployment

This script provides:
- Force redeploy (cache refresh)
- Verification
- Quick testing
"""

import os
import sys
import json
import boto3

REGION = os.getenv('AWS_REGION', 'eu-west-2')
PROJECT_NAME = os.getenv('PROJECT_NAME', 'moj-de-user-guidance')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'dev')
API_NAME = f"{PROJECT_NAME}-{ENVIRONMENT}-api"


def get_api_id() -> str:
    """Find API Gateway ID by name."""
    client = boto3.client('apigateway', region_name=REGION)
    apis = client.get_rest_apis()
    
    api = next((a for a in apis['items'] if a['name'] == API_NAME), None)
    if not api:
        raise Exception(f"API '{API_NAME}' not found. Run terraform apply first.")
    
    return api['id']


def force_redeploy():
    """Force redeploy to refresh stage."""
    import time
    
    client = boto3.client('apigateway', region_name=REGION)
    api_id = get_api_id()
    
    print(f"✓ Found API: {api_id}")
    print(f"✓ Redeploying to '{ENVIRONMENT}' stage...")
    
    deployment = client.create_deployment(
        restApiId=api_id,
        stageName=ENVIRONMENT,
        description=f'Force redeploy at {time.strftime("%Y-%m-%d %H:%M:%S")}'
    )
    
    print(f"✅ Deployed: {deployment['id']}")
    print(f"\n🔗 Endpoint: https://{api_id}.execute-api.{REGION}.amazonaws.com/{ENVIRONMENT}")


def verify_configuration():
    """Verify API Gateway configuration."""
    client = boto3.client('apigateway', region_name=REGION)
    api_id = get_api_id()
    
    print(f"\n📋 API Gateway: {api_id}")
    
    # Check resources
    resources = client.get_resources(restApiId=api_id)
    paths = [r['path'] for r in resources['items']]
    print(f"   Resources: {', '.join(paths)}")
    
    # Check authorizer
    authorizers = client.get_authorizers(restApiId=api_id)
    if authorizers.get('items'):
        print(f"   Authorizer: ✓ Configured")
    else:
        print(f"   Authorizer: ✗ Not configured")
    
    # Check stage
    try:
        stage = client.get_stage(restApiId=api_id, stageName=ENVIRONMENT)
        print(f"   Stage '{ENVIRONMENT}': ✓ Active")
        print(f"   Cache: {'Enabled' if stage.get('cacheClusterEnabled') else 'Disabled'}")
    except:
        print(f"   Stage '{ENVIRONMENT}': ✗ Not found")
    
    print(f"\n🔗 Endpoint: https://{api_id}.execute-api.{REGION}.amazonaws.com/{ENVIRONMENT}")


def test_endpoint():
    """Quick test of the API endpoint."""
    import subprocess
    
    api_id = get_api_id()
    endpoint = f"https://{api_id}.execute-api.{REGION}.amazonaws.com/{ENVIRONMENT}/ask"
    auth_token = os.getenv('AUTH_TOKEN', '')
    
    print(f"\n🧪 Testing: {endpoint}")
    
    cmd = [
        'curl', '-s', '-X', 'POST', endpoint,
        '-H', 'Content-Type: application/json',
        '-d', '{"text": "What is R-studio?"}'
    ]
    
    if auth_token:
        cmd.extend(['-H', f'Authorization: Bearer {auth_token}'])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    print(f"\n📤 Response:\n{result.stdout[:500]}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='API Gateway utilities')
    parser.add_argument('--redeploy', action='store_true', help='Force redeploy stage')
    parser.add_argument('--verify', action='store_true', help='Verify configuration')
    parser.add_argument('--test', action='store_true', help='Test endpoint')
    
    args = parser.parse_args()
    
    print("=" * 50)
    print("API GATEWAY UTILITIES")
    print("=" * 50)
    print(f"API Name: {API_NAME}")
    print(f"Region:   {REGION}")
    print("\nℹ️  Infrastructure managed by Terraform")
    
    try:
        if args.redeploy:
            force_redeploy()
        elif args.verify:
            verify_configuration()
        elif args.test:
            test_endpoint()
        else:
            verify_configuration()
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()