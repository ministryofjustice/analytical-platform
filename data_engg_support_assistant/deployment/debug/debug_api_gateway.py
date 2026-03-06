"""
Debug API Gateway REST API configuration
- Check resources, methods, integrations
- Inspect stage settings
- Verify authorizers
"""

import boto3
import json
import sys
import os
import re
from pathlib import Path

# Add project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))
from config import REGION, FUNCTION_NAME

apigw_client = boto3.client('apigateway', region_name=REGION)

# Global masking flag
MASK_SENSITIVE_DATA = os.getenv("MASK_SENSITIVE_DATA", "true").lower() == "true"


def mask_account_id(text):
    """Mask AWS account ID"""
    if not MASK_SENSITIVE_DATA:
        return text
    return re.sub(r'\b\d{12}\b', 'XXXXXXXXXXXX', str(text))


def mask_api_id(text):
    """Mask API Gateway ID"""
    if not MASK_SENSITIVE_DATA:
        return text
    return re.sub(r'\b[a-z0-9]{10}\b', 'XXXXXXXXXX', str(text))


def mask_resource_id(text):
    """Mask resource IDs"""
    if not MASK_SENSITIVE_DATA:
        return text
    return re.sub(r'\b[a-z0-9]{6,}\b', 'XXXXXX', str(text))


def mask_arn(text):
    """Mask sensitive parts of ARN"""
    if not MASK_SENSITIVE_DATA:
        return text
    
    text = re.sub(r':(\d{12}):', ':XXXXXXXXXXXX:', str(text))
    text = re.sub(r'/([a-z0-9]{10})/', '/XXXXXXXXXX/', text)
    text = re.sub(
        r'(arn:aws:lambda:[^:]+:)\d{12}(:function:[^/]+)',
        r'\1XXXXXXXXXXXX\2',
        text
    )
    return text


def mask_url(url):
    """Mask API Gateway URL"""
    if not MASK_SENSITIVE_DATA:
        return url
    
    url = re.sub(
        r'https://([a-z0-9]{10})\.execute-api',
        r'https://XXXXXXXXXX.execute-api',
        str(url)
    )
    return url


def mask_dict(data):
    """Recursively mask sensitive data in dictionaries"""
    if not MASK_SENSITIVE_DATA:
        return data
    
    if isinstance(data, dict):
        masked = {}
        for key, value in data.items():
            if key in ['ResponseMetadata', 'HTTPHeaders']:
                continue
            masked[key] = mask_dict(value)
        return masked
    elif isinstance(data, list):
        return [mask_dict(item) for item in data]
    elif isinstance(data, str):
        value = mask_account_id(data)
        value = mask_api_id(value)
        value = mask_arn(value)
        value = mask_url(value)
        return value
    return data


def get_api_gateway_id(api_name=None):
    """Get REST API Gateway ID by name"""
    if api_name is None:
        api_name = f"{FUNCTION_NAME}-api"
    
    apis = apigw_client.get_rest_apis()
    for api in apis.get('items', []):
        if api['name'] == api_name:
            api_id = api['id']
            if MASK_SENSITIVE_DATA:
                os.environ['_REAL_API_ID'] = api_id
                return mask_api_id(api_id)
            return api_id
    
    raise Exception(f"REST API Gateway '{api_name}' not found")


def _get_real_api_id():
    """Get the real (unmasked) API ID for API calls"""
    if MASK_SENSITIVE_DATA and '_REAL_API_ID' in os.environ:
        return os.environ['_REAL_API_ID']
    return get_api_gateway_id()


def get_api_gateway_url(api_id, stage='prod'):
    """Get REST API Gateway URL"""
    real_api_id = _get_real_api_id() if MASK_SENSITIVE_DATA else api_id
    url = f"https://{real_api_id}.execute-api.{REGION}.amazonaws.com/{stage}"
    return mask_url(url)


def check_resources(api_id):
    """Check all resources and methods"""
    print("\n" + "="*80)
    print("API GATEWAY RESOURCES & METHODS")
    print("="*80)
    
    real_api_id = _get_real_api_id() if MASK_SENSITIVE_DATA else api_id
    resources = apigw_client.get_resources(RestApiId=real_api_id)
    
    for resource in resources.get('items', []):
        path = resource['path']
        resource_id = mask_resource_id(resource['id'])
        
        print(f"\nResource: {path}")
        print(f"  Resource ID: {resource_id}")
        
        methods = resource.get('resourceMethods', {})
        if methods:
            print(f"  Methods: {', '.join(methods.keys())}")
            
            for method in methods.keys():
                try:
                    method_response = apigw_client.get_method(
                        RestApiId=real_api_id,
                        ResourceId=resource['id'],
                        HttpMethod=method
                    )
                    
                    auth_type = method_response.get('authorizationType', 'NONE')
                    authorizer_id = method_response.get('authorizerId', 'None')
                    api_key_req = method_response.get('apiKeyRequired', False)
                    
                    print(f"    {method}:")
                    print(f"      Authorization: {auth_type}")
                    if authorizer_id != 'None':
                        print(f"      Authorizer ID: {mask_resource_id(authorizer_id)}")
                    print(f"      API Key Required: {api_key_req}")
                    
                except Exception as e:
                    print(f"    {method}: Error - {str(e)}")
        else:
            print("  No methods configured")


def check_integrations(api_id):
    """Check all integrations"""
    print("\n" + "="*80)
    print("INTEGRATIONS")
    print("="*80)
    
    real_api_id = _get_real_api_id() if MASK_SENSITIVE_DATA else api_id
    resources = apigw_client.get_resources(RestApiId=real_api_id)
    
    for resource in resources.get('items', []):
        methods = resource.get('resourceMethods', {})
        
        for method in methods.keys():
            try:
                integration = apigw_client.get_integration(
                    RestApiId=real_api_id,
                    ResourceId=resource['id'],
                    HttpMethod=method
                )
                
                integration_type = integration.get('type', 'N/A')
                uri = mask_arn(integration.get('uri', 'N/A'))
                integration_method = integration.get('httpMethod', 'N/A')
                timeout = integration.get('timeoutInMillis', 'N/A')
                
                print(f"\n{method} {resource['path']}")
                print(f"  Type: {integration_type}")
                print(f"  URI: {uri}")
                print(f"  Method: {integration_method}")
                print(f"  Timeout: {timeout}ms")
                
            except apigw_client.exceptions.NotFoundException:
                print(f"\n{method} {resource['path']}")
                print(f"  No integration configured")


def check_authorizers(api_id):
    """Check all authorizers"""
    print("\n" + "="*80)
    print("AUTHORIZERS")
    print("="*80)
    
    real_api_id = _get_real_api_id() if MASK_SENSITIVE_DATA else api_id
    authorizers = apigw_client.get_authorizers(RestApiId=real_api_id)
    
    if not authorizers.get('items'):
        print("  No authorizers configured")
        return
    
    for authorizer in authorizers.get('items', []):
        name = authorizer['name']
        auth_id = mask_resource_id(authorizer['id'])
        auth_type = authorizer['type']
        uri = mask_arn(authorizer.get('authorizerUri', 'N/A'))
        identity_source = authorizer.get('identitySource', 'N/A')
        ttl = authorizer.get('authorizerResultTtlInSeconds', 'N/A')
        
        print(f"\nAuthorizer: {name}")
        print(f"  ID: {auth_id}")
        print(f"  Type: {auth_type}")
        print(f"  URI: {uri}")
        print(f"  Identity Source: {identity_source}")
        print(f"  Result TTL: {ttl}s")


def check_stage(api_id, stage_name='prod'):
    """Check stage configuration"""
    print("\n" + "="*80)
    print("STAGE CONFIGURATION")
    print("="*80)
    
    real_api_id = _get_real_api_id() if MASK_SENSITIVE_DATA else api_id
    
    try:
        stage = apigw_client.get_stage(RestApiId=real_api_id, StageName=stage_name)
        
        deployment_id = mask_resource_id(stage.get('deploymentId', 'N/A'))
        cache_enabled = stage.get('cacheClusterEnabled', False)
        cache_size = stage.get('cacheClusterSize', 'N/A')
        
        print(f"Stage: {stage_name}")
        print(f"Deployment ID: {deployment_id}")
        print(f"Cache Enabled: {cache_enabled}")
        if cache_enabled:
            print(f"Cache Size: {cache_size}")
        
        # Method settings
        method_settings = stage.get('methodSettings', {})
        if method_settings:
            print(f"\nMethod Settings:")
            for path, settings in method_settings.items():
                print(f"  {path}:")
                print(f"    Caching: {settings.get('cachingEnabled', False)}")
                print(f"    Logging: {settings.get('loggingLevel', 'OFF')}")
                
    except apigw_client.exceptions.NotFoundException:
        print(f"Stage '{stage_name}' not found")


def check_deployments(api_id):
    """Check recent deployments"""
    print("\n" + "="*80)
    print("RECENT DEPLOYMENTS")
    print("="*80)
    
    real_api_id = _get_real_api_id() if MASK_SENSITIVE_DATA else api_id
    deployments = apigw_client.get_deployments(RestApiId=real_api_id, limit=5)
    
    for deployment in deployments.get('items', []):
        deployment_id = mask_resource_id(deployment['id'])
        created_date = deployment.get('createdDate', 'N/A')
        description = deployment.get('description', 'No description')
        
        print(f"\nDeployment ID: {deployment_id}")
        print(f"  Created: {created_date}")
        print(f"  Description: {description}")


def snapshot():
    """Complete state snapshot"""
    print("="*80)
    print("REST API GATEWAY - CURRENT STATE SNAPSHOT")
    print("="*80)
    
    if MASK_SENSITIVE_DATA:
        print("ℹ️  Sensitive Data Masking: ENABLED")
        print("   Set MASK_SENSITIVE_DATA=false to see actual values\n")
    
    try:
        api_id = get_api_gateway_id()
        
        # API info
        real_api_id = _get_real_api_id() if MASK_SENSITIVE_DATA else api_id
        api = apigw_client.get_rest_api(RestApiId=real_api_id)
        
        api_name = api['name']
        api_endpoint = get_api_gateway_url(api_id)
        
        print(f"\nAPI: {api_name}")
        print(f"API ID: {api_id}")
        print(f"Endpoint: {api_endpoint}")
        
        # Check resources and methods
        check_resources(api_id)
        
        # Check integrations
        check_integrations(api_id)
        
        # Check authorizers
        check_authorizers(api_id)
        
        # Check stage
        check_stage(api_id)
        
        # Check deployments
        check_deployments(api_id)
        
    except Exception as e:
        print(f"\n❌ Error: {mask_arn(str(e))}")
        import traceback
        traceback.print_exc()


def remove_authorizer_from_method(resource_path='/ask', http_method='POST'):
    """Remove authorizer requirement from a method"""
    print("\n" + "="*80)
    print(f"REMOVING AUTHORIZER FROM: {http_method} {resource_path}")
    print("="*80)
    
    if MASK_SENSITIVE_DATA:
        print("⚠️  Skipping actual changes (MASK_SENSITIVE_DATA=true)")
        print("   Set MASK_SENSITIVE_DATA=false to execute changes")
        return
    
    real_api_id = _get_real_api_id()
    resources = apigw_client.get_resources(RestApiId=real_api_id)
    
    for resource in resources.get('items', []):
        if resource['path'] == resource_path:
            resource_id = resource['id']
            
            try:
                method = apigw_client.get_method(
                    RestApiId=real_api_id,
                    ResourceId=resource_id,
                    HttpMethod=http_method
                )
                
                print(f"Current config:")
                print(f"  AuthorizationType: {method.get('authorizationType')}")
                print(f"  AuthorizerId: {method.get('authorizerId', 'None')}")
                
                # Update method
                apigw_client.update_method(
                    RestApiId=real_api_id,
                    ResourceId=resource_id,
                    HttpMethod=http_method,
                    patchOperations=[
                        {
                            'op': 'replace',
                            'path': '/authorizationType',
                            'value': 'NONE'
                        }
                    ]
                )
                
                print(f"✓ Method updated to NONE authorization")
                print(f"⚠️  Deploy API for changes to take effect:")
                print(f"   python deployment/deploy_api_gateway.py --refresh")
                return
                
            except apigw_client.exceptions.NotFoundException:
                print(f"✗ Method {http_method} not found on {resource_path}")
                return
    
    print(f"✗ Resource '{resource_path}' not found")


def delete_authorizer(authorizer_id):
    """Delete a specific authorizer"""
    print(f"\nDeleting authorizer: {mask_resource_id(authorizer_id)}")
    
    if MASK_SENSITIVE_DATA:
        print("⚠️  Skipping actual changes (MASK_SENSITIVE_DATA=true)")
        return
    
    real_api_id = _get_real_api_id()
    
    try:
        apigw_client.delete_authorizer(
            RestApiId=real_api_id,
            AuthorizerId=authorizer_id
        )
        print("✓ Authorizer deleted")
        print("⚠️  Deploy API for changes to take effect")
    except Exception as e:
        error_msg = mask_arn(str(e))
        print(f"✗ Error: {error_msg}")


def export_config_to_file(filename=None):
    """Export masked configuration to file"""
    if filename is None:
        from datetime import datetime
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"rest_api_config_{timestamp}.json"
    
    print(f"\nℹ️  Exporting configuration to: {filename}")
    
    real_api_id = _get_real_api_id()
    
    config = {
        'api': mask_dict(apigw_client.get_rest_api(RestApiId=real_api_id)),
        'resources': mask_dict(apigw_client.get_resources(RestApiId=real_api_id)),
        'authorizers': mask_dict(apigw_client.get_authorizers(RestApiId=real_api_id)),
        'stages': mask_dict(apigw_client.get_stages(RestApiId=real_api_id)),
        'deployments': mask_dict(apigw_client.get_deployments(RestApiId=real_api_id, limit=5))
    }
    
    with open(filename, 'w') as f:
        json.dump(config, f, indent=2, default=str)
    
    print(f"✓ Configuration exported (masked: {MASK_SENSITIVE_DATA})")


if __name__ == "__main__":
    # Run complete snapshot
    snapshot()
    
    # Uncomment to export config:
    # export_config_to_file()
    
    # Uncomment to remove authorizer:
    # remove_authorizer_from_method('/ask', 'POST')
    
    # Uncomment to delete authorizer:
    # delete_authorizer('your_authorizer_id')


# Usage examples:
# python debug_api_gateway_rest.py
# MASK_SENSITIVE_DATA=false python debug_api_gateway_rest.py
# python -c "from debug_api_gateway_rest import export_config_to_file; export_config_to_file()"