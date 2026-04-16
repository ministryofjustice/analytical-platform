"""
API Gateway Deployment Script

Infrastructure (Lambda functions, IAM) managed by Terraform.
This script ONLY configures API Gateway resources.

Usage:
    python deployment/deploy_api_gateway.py              # Full deploy
    python deployment/deploy_api_gateway.py --refresh    # Force redeploy stage
    python deployment/deploy_api_gateway.py --update-auth # Update authorizer config only

Prerequisites:
    1. Terraform apply completed: cd terraform/environments/dev && terraform apply
    2. Lambda code deployed: python deployment/deploy_lambda.py
"""

import os
import sys
import json
import time
import boto3
from typing import Optional

from dotenv import load_dotenv
load_dotenv()

# Configuration - must match Terraform naming
REGION = os.getenv('AWS_REGION', 'eu-west-2')
PROJECT_NAME = os.getenv('PROJECT_NAME', 'smartrag')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'dev')

FUNCTION_NAME = os.getenv('FUNCTION_NAME', f'{PROJECT_NAME}-{ENVIRONMENT}-smart-rag')
AUTHORIZER_FUNCTION_NAME = os.getenv('AUTHORIZER_FUNCTION_NAME', f'{FUNCTION_NAME}-authorizer')
AUTH_TOKEN = os.getenv('AUTH_TOKEN', '')


class APIGatewayDeployer:
    """Handles API Gateway deployment with Lambda authorizer and CORS."""
    
    def __init__(self, function_name: str = None, api_name: str = None):
        self.function_name = function_name or FUNCTION_NAME
        self.authorizer_function_name = AUTHORIZER_FUNCTION_NAME
        self.api_name = api_name or f"{self.function_name}-api"
        self.region = REGION
        self.environment = ENVIRONMENT
        
        # Validate configuration
        if not self.function_name:
            raise ValueError("FUNCTION_NAME not set in .env")
        
        # AWS clients
        self.apigw_client = boto3.client('apigateway', region_name=self.region)
        self.lambda_client = boto3.client('lambda', region_name=self.region)
        
        # Deployment state
        self.api_id: Optional[str] = None
        self.lambda_arn: Optional[str] = None
        self.authorizer_arn: Optional[str] = None
        self.authorizer_id: Optional[str] = None
        self.validator_id: Optional[str] = None
        
        print(f"ℹ️  Initializing API Gateway deployment")
        print(f"   API Name: {self.api_name}")
        print(f"   Environment: {self.environment}")
    
    def deploy(self) -> Optional[str]:
        """
        Main deployment orchestration.
        
        Returns:
            str: API Gateway invoke URL or None if failed
        """
        try:
            self._validate_lambdas()
            self._setup_api()
            self._setup_resources()
            self._setup_request_validation()
            self._setup_authorizer()
            self._configure_methods()
            self._configure_lambda_permissions()
            self._deploy_to_stage()
            self._verify_configuration()
            
            endpoint = self._get_endpoint_url()
            self._print_success_summary(endpoint)
            
            return endpoint
            
        except Exception as e:
            print(f"\n❌ API Gateway deployment failed: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def _validate_lambdas(self):
        """Step 1: Validate Lambda functions exist (created by Terraform)."""
        print("\n✓ 1. Validating Lambda functions...")
        
        # Main Lambda
        try:
            response = self.lambda_client.get_function(FunctionName=self.function_name)
            self.lambda_arn = response['Configuration']['FunctionArn']
            print(f"   ✓ Main Lambda: {self.function_name}")
        except self.lambda_client.exceptions.ResourceNotFoundException:
            raise Exception(
                f"Lambda '{self.function_name}' not found!\n"
                "   Run: cd terraform/environments/dev && terraform apply"
            )
        
        # Authorizer Lambda
        try:
            response = self.lambda_client.get_function(FunctionName=self.authorizer_function_name)
            self.authorizer_arn = response['Configuration']['FunctionArn']
            print(f"   ✓ Authorizer Lambda: {self.authorizer_function_name}")
        except self.lambda_client.exceptions.ResourceNotFoundException:
            print(f"   ⚠️  Authorizer Lambda not found: {self.authorizer_function_name}")
            print("      API will be deployed without authentication")
            self.authorizer_arn = None
    
    def _setup_api(self):
        """Step 2: Create or find existing REST API."""
        print(f"\n✓ 2. Setting up REST API '{self.api_name}'...")
        
        # Check for existing API
        apis = self.apigw_client.get_rest_apis()
        existing_api = next(
            (api for api in apis.get('items', []) if api['name'] == self.api_name),
            None
        )
        
        if existing_api:
            self.api_id = existing_api['id']
            print(f"   ✓ Found existing API: {self.api_id}")
        else:
            response = self.apigw_client.create_rest_api(
                name=self.api_name,
                description=f'REST API Gateway for {self.function_name} Lambda chatbot',
                endpointConfiguration={'types': ['REGIONAL']}
            )
            self.api_id = response['id']
            print(f"   ✓ Created new API: {self.api_id}")
    
    def _setup_resources(self):
        """Step 3: Create /ask and /feedback resources."""
        print("\n✓ 3. Setting up API resources...")
        
        # Get root resource
        resources = self.apigw_client.get_resources(restApiId=self.api_id)
        root_id = next(r['id'] for r in resources['items'] if r['path'] == '/')
        
        # /ask resource
        ask_resource = next(
            (r for r in resources['items'] if r['path'] == '/ask'),
            None
        )
        
        if ask_resource:
            self.resource_id = ask_resource['id']
            print(f"   ✓ Found existing /ask: {self.resource_id}")
        else:
            response = self.apigw_client.create_resource(
                restApiId=self.api_id,
                parentId=root_id,
                pathPart='ask'
            )
            self.resource_id = response['id']
            print(f"   ✓ Created /ask: {self.resource_id}")
        
        # Refresh resources
        resources = self.apigw_client.get_resources(restApiId=self.api_id)
        
        # /feedback resource
        feedback_resource = next(
            (r for r in resources['items'] if r['path'] == '/feedback'),
            None
        )
        
        if feedback_resource:
            self.feedback_resource_id = feedback_resource['id']
            print(f"   ✓ Found existing /feedback: {self.feedback_resource_id}")
        else:
            response = self.apigw_client.create_resource(
                restApiId=self.api_id,
                parentId=root_id,
                pathPart='feedback'
            )
            self.feedback_resource_id = response['id']
            print(f"   ✓ Created /feedback: {self.feedback_resource_id}")
    
    def _setup_request_validation(self):
        """Step 4: Create request validator and model."""
        print("\n✓ 4. Setting up request validation...")
        
        try:
            # Check for existing validator
            validators = self.apigw_client.get_request_validators(restApiId=self.api_id)
            validator = next(
                (v for v in validators.get('items', []) 
                 if v['name'] == 'chatbot-request-validator'),
                None
            )
            
            if validator:
                self.validator_id = validator['id']
                print(f"   ✓ Found existing validator: {self.validator_id}")
            else:
                response = self.apigw_client.create_request_validator(
                    restApiId=self.api_id,
                    name='chatbot-request-validator',
                    validateRequestBody=True,
                    validateRequestParameters=False
                )
                self.validator_id = response['id']
                print(f"   ✓ Created validator: {self.validator_id}")
            
            # Create/verify model
            self._create_request_model()
            
        except Exception as e:
            print(f"   ⚠️  Request validation setup warning: {e}")
            print("   → Continuing without validation (Lambda will validate)")
            self.validator_id = None
            self.model_name = 'Empty'
    
    def _create_request_model(self):
        """Create JSON schema model for request validation."""
        try:
            response = self.apigw_client.get_model(
                restApiId=self.api_id,
                modelName='ChatbotRequestModel'
            )
            self.model_name = response['name']
            print(f"   ✓ Found existing model: {self.model_name}")
        except self.apigw_client.exceptions.NotFoundException:
            schema = {
                "$schema": "http://json-schema.org/draft-04/schema#",
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "minLength": 1,
                        "maxLength": 2000,
                        "description": "User question or message"
                    }
                },
                "required": ["text"]
            }
            
            response = self.apigw_client.create_model(
                restApiId=self.api_id,
                name='ChatbotRequestModel',
                contentType='application/json',
                schema=json.dumps(schema)
            )
            self.model_name = response['name']
            print(f"   ✓ Created model: {self.model_name}")
    
    def _setup_authorizer(self):
        """Step 5: Configure Lambda authorizer (Lambda already exists via Terraform)."""
        print("\n✓ 5. Setting up Lambda Authorizer...")
        
        if not self.authorizer_arn:
            print("   ⚠️  No authorizer Lambda - API will be public")
            self.authorizer_id = None
            return
        
        if not AUTH_TOKEN:
            print("   ⚠️  AUTH_TOKEN not set - API will be public")
            self.authorizer_id = None
            return
        
        # Create/update API Gateway authorizer (references existing Lambda)
        authorizers = self.apigw_client.get_authorizers(restApiId=self.api_id)
        existing_authorizer = next(
            (a for a in authorizers.get('items', []) 
             if a.get('name') == 'lambda-authorizer'),
            None
        )
        
        if existing_authorizer:
            self.authorizer_id = existing_authorizer['id']
            print(f"   ✓ Found existing authorizer: {self.authorizer_id}")
            
            # Update authorizer configuration
            self.apigw_client.update_authorizer(
                restApiId=self.api_id,
                authorizerId=self.authorizer_id,
                patchOperations=[
                    {
                        'op': 'replace',
                        'path': '/authorizerUri',
                        'value': f'arn:aws:apigateway:{self.region}:lambda:path/2015-03-31/functions/{self.authorizer_arn}/invocations'
                    },
                    {
                        'op': 'replace',
                        'path': '/authorizerResultTtlInSeconds',
                        'value': '0'
                    }
                ]
            )
            print("   ✓ Updated authorizer configuration")
        else:
            response = self.apigw_client.create_authorizer(
                restApiId=self.api_id,
                name='lambda-authorizer',
                type='REQUEST',
                authorizerUri=f'arn:aws:apigateway:{self.region}:lambda:path/2015-03-31/functions/{self.authorizer_arn}/invocations',
                authorizerResultTtlInSeconds=0,
                identitySource='method.request.header.Authorization'
            )
            self.authorizer_id = response['id']
            print(f"   ✓ Created authorizer: {self.authorizer_id}")
        
        # Configure authorizer Lambda permissions
        self._configure_authorizer_permissions()
    
    def _configure_authorizer_permissions(self):
        """Add API Gateway invoke permissions for authorizer Lambda."""
        account_id = self.authorizer_arn.split(':')[4]
        
        # Remove old permissions
        self._cleanup_lambda_permissions(self.authorizer_function_name)
        
        # Add new permission
        try:
            self.lambda_client.add_permission(
                FunctionName=self.authorizer_function_name,
                StatementId=f'apigateway-authorizer-invoke-{self.environment}',
                Action='lambda:InvokeFunction',
                Principal='apigateway.amazonaws.com',
                SourceArn=f'arn:aws:execute-api:{self.region}:{account_id}:{self.api_id}/{self.environment}/*'
            )
            print("   ✓ Authorizer permission configured")
        except Exception as e:
            if 'ResourceConflictException' not in str(e):
                print(f"   ⚠️  Authorizer permission warning: {e}")
    
    def _configure_methods(self):
        """Step 6: Configure POST and OPTIONS methods."""
        print("\n✓ 6. Configuring HTTP methods...")
        
        self._configure_post_method(self.resource_id, '/ask')
        self._configure_cors(self.resource_id)
        
        self._configure_post_method(self.feedback_resource_id, '/feedback')
        self._configure_cors(self.feedback_resource_id)
    
    def _configure_post_method(self, resource_id: str, path: str):
        """Configure POST method with Lambda integration."""
        print(f"   → Configuring POST {path}...")
        
        # Remove existing method
        try:
            self.apigw_client.delete_method(
                restApiId=self.api_id,
                resourceId=resource_id,
                httpMethod='POST'
            )
            time.sleep(1)
        except self.apigw_client.exceptions.NotFoundException:
            pass
        
        # Create method
        method_config = {
            'restApiId': self.api_id,
            'resourceId': resource_id,
            'httpMethod': 'POST',
            'authorizationType': 'CUSTOM' if self.authorizer_id else 'NONE',
            'apiKeyRequired': False
        }
        
        if self.authorizer_id:
            method_config['authorizerId'] = self.authorizer_id
        
        if path == '/ask' and self.validator_id:
            method_config['requestValidatorId'] = self.validator_id
            method_config['requestModels'] = {'application/json': self.model_name}
        
        self.apigw_client.put_method(**method_config)
        
        # Method response
        try:
            self.apigw_client.put_method_response(
                restApiId=self.api_id,
                resourceId=resource_id,
                httpMethod='POST',
                statusCode='200',
                responseParameters={
                    'method.response.header.Access-Control-Allow-Origin': False
                }
            )
        except Exception as e:
            print(f"      Warning: method response: {e}")
        
        # Lambda integration
        self.apigw_client.put_integration(
            restApiId=self.api_id,
            resourceId=resource_id,
            httpMethod='POST',
            type='AWS_PROXY',
            integrationHttpMethod='POST',
            uri=f'arn:aws:apigateway:{self.region}:lambda:path/2015-03-31/functions/{self.lambda_arn}/invocations'
        )
        
        print(f"   ✓ POST {path} configured")
    
    def _configure_cors(self, resource_id: str):
        """Configure CORS with OPTIONS method."""
        try:
            try:
                self.apigw_client.get_method(
                    restApiId=self.api_id,
                    resourceId=resource_id,
                    httpMethod='OPTIONS'
                )
            except self.apigw_client.exceptions.NotFoundException:
                self.apigw_client.put_method(
                    restApiId=self.api_id,
                    resourceId=resource_id,
                    httpMethod='OPTIONS',
                    authorizationType='NONE',
                    apiKeyRequired=False
                )
            
            self.apigw_client.put_integration(
                restApiId=self.api_id,
                resourceId=resource_id,
                httpMethod='OPTIONS',
                type='MOCK',
                requestTemplates={'application/json': '{"statusCode": 200}'}
            )
            
            self.apigw_client.put_method_response(
                restApiId=self.api_id,
                resourceId=resource_id,
                httpMethod='OPTIONS',
                statusCode='200',
                responseParameters={
                    'method.response.header.Access-Control-Allow-Headers': False,
                    'method.response.header.Access-Control-Allow-Methods': False,
                    'method.response.header.Access-Control-Allow-Origin': False
                },
                responseModels={'application/json': 'Empty'}
            )
            
            self.apigw_client.put_integration_response(
                restApiId=self.api_id,
                resourceId=resource_id,
                httpMethod='OPTIONS',
                statusCode='200',
                responseParameters={
                    'method.response.header.Access-Control-Allow-Headers': "'Content-Type,Authorization'",
                    'method.response.header.Access-Control-Allow-Methods': "'POST,OPTIONS'",
                    'method.response.header.Access-Control-Allow-Origin': "'*'"
                },
                responseTemplates={'application/json': ''}
            )
            
        except Exception as e:
            print(f"   ⚠️  CORS setup warning: {e}")
    
    def _configure_lambda_permissions(self):
        """Step 7: Configure Lambda invoke permissions."""
        print("\n✓ 7. Configuring Lambda permissions...")
        
        self._cleanup_lambda_permissions(self.function_name)
        
        account_id = self.lambda_arn.split(':')[4]
        source_arn = f"arn:aws:execute-api:{self.region}:{account_id}:{self.api_id}/{self.environment}/*"
        
        try:
            self.lambda_client.add_permission(
                FunctionName=self.function_name,
                StatementId=f'apigateway-invoke-{self.environment}',
                Action='lambda:InvokeFunction',
                Principal='apigateway.amazonaws.com',
                SourceArn=source_arn
            )
            print(f"   ✓ Permission added for {self.environment} stage")
        except Exception as e:
            if 'ResourceConflictException' not in str(e):
                print(f"   ⚠️  Permission warning: {e}")
    
    def _cleanup_lambda_permissions(self, function_name: str):
        """Remove old API Gateway permissions from Lambda."""
        try:
            policy = self.lambda_client.get_policy(FunctionName=function_name)
            statements = json.loads(policy['Policy']).get('Statement', [])
            
            for statement in statements:
                if statement.get('Principal', {}).get('Service') == 'apigateway.amazonaws.com':
                    self.lambda_client.remove_permission(
                        FunctionName=function_name,
                        StatementId=statement['Sid']
                    )
        except Exception:
            pass
    
    def _deploy_to_stage(self):
        """Step 8: Deploy API to stage."""
        print(f"\n✓ 8. Deploying to '{self.environment}' stage...")
        
        try:
            deployment = self.apigw_client.create_deployment(
                restApiId=self.api_id,
                stageName=self.environment,
                description=f'Deployment at {time.strftime("%Y-%m-%d %H:%M:%S")}'
            )
            print(f"   ✓ Deployed: {deployment['id']}")
        except Exception as e:
            print(f"   ⚠️  Deployment warning: {e}")
    
    def _verify_configuration(self):
        """Step 9: Verify caching is disabled."""
        print("\n✓ 9. Verifying configuration...")
        
        try:
            stage = self.apigw_client.get_stage(
                restApiId=self.api_id,
                stageName=self.environment
            )
            
            if stage.get('cacheClusterEnabled', False):
                self.apigw_client.update_stage(
                    restApiId=self.api_id,
                    stageName=self.environment,
                    patchOperations=[
                        {'op': 'replace', 'path': '/cacheClusterEnabled', 'value': 'false'}
                    ]
                )
                print("   ✓ Caching disabled")
            else:
                print("   ✓ No caching enabled")
                
        except Exception as e:
            print(f"   ⚠️  Verification warning: {e}")
    
    def _get_endpoint_url(self) -> str:
        """Get the full API endpoint URL."""
        return f"https://{self.api_id}.execute-api.{self.region}.amazonaws.com/{self.environment}"
    
    def _print_success_summary(self, endpoint: str):
        """Print deployment success summary."""
        print("\n" + "=" * 70)
        print("✅ API Gateway deployment complete!")
        print("=" * 70)
        
        print(f"\n📋 API Details:")
        print(f"   API ID:       {self.api_id}")
        print(f"   API Name:     {self.api_name}")
        print(f"   Region:       {self.region}")
        print(f"   Stage:        {self.environment}")
        print(f"   Lambda:       {self.function_name}")
        print(f"   Auth:         {'✓ Enabled' if self.authorizer_id else '✗ Disabled (Public)'}")
        
        print(f"\n🔗 Endpoints:")
        print(f"   {endpoint}/ask")
        print(f"   {endpoint}/feedback")
        
        if self.authorizer_id:
            print(f"\n🧪 Test (authenticated):")
            print(f"""   curl -X POST {endpoint}/ask \\
     -H "Content-Type: application/json" \\
     -H "Authorization: Bearer $AUTH_TOKEN" \\
     -d '{{"text": "What is R-studio?"}}'""")
        else:
            print(f"\n🧪 Test (public):")
            print(f"""   curl -X POST {endpoint}/ask \\
     -H "Content-Type: application/json" \\
     -d '{{"text": "What is R-studio?"}}'""")


def force_api_refresh(api_id: str = None) -> bool:
    """Force API Gateway deployment refresh."""
    apigw_client = boto3.client('apigateway', region_name=REGION)
    
    try:
        if api_id is None:
            api_name = f"{FUNCTION_NAME}-api"
            apis = apigw_client.get_rest_apis()
            api = next((a for a in apis['items'] if a['name'] == api_name), None)
            
            if not api:
                print(f"❌ API '{api_name}' not found")
                return False
            
            api_id = api['id']
            print(f"✓ Detected API: {api_id}")
        
        deployment = apigw_client.create_deployment(
            restApiId=api_id,
            stageName=ENVIRONMENT,
            description=f'Force refresh at {time.strftime("%Y-%m-%d %H:%M:%S")}'
        )
        
        print(f"✅ Deployment refreshed: {deployment['id']}")
        return True
        
    except Exception as e:
        print(f"❌ Refresh failed: {e}")
        return False


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Deploy API Gateway (Lambda managed by Terraform)'
    )
    parser.add_argument('--refresh', action='store_true', help='Force redeploy stage')
    parser.add_argument('--update-auth', action='store_true', help='Update authorizer config only')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("API GATEWAY DEPLOYMENT")
    print("=" * 60)
    print(f"Region:      {REGION}")
    print(f"Environment: {ENVIRONMENT}")
    print(f"Main Lambda: {FUNCTION_NAME}")
    print(f"Authorizer:  {AUTHORIZER_FUNCTION_NAME}")
    print("\nℹ️  Lambda functions managed by Terraform")
    print("ℹ️  This script configures API Gateway")
    
    if args.refresh:
        print("\n🔄 Forcing API Gateway refresh...\n")
        success = force_api_refresh()
    elif args.update_auth:
        print("\n🔐 Updating authorizer only...\n")
        deployer = APIGatewayDeployer()
        deployer._validate_lambdas()
        deployer._setup_api()
        deployer._setup_authorizer()
        success = deployer.authorizer_id is not None
    else:
        deployer = APIGatewayDeployer()
        success = deployer.deploy() is not None
    
    return success


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)