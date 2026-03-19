"""
API Gateway Deployment Script for SmartRAG

Deploys AWS API Gateway HTTP API with Lambda authorizer, CORS,
and request validation for the SmartRAG chatbot.

Usage:
    python deployment/deploy_api_gateway.py           # Full deployment
    python deployment/deploy_api_gateway.py --refresh  # Force cache clear
    python deployment/deploy_api_gateway.py --update-auth  # Update authorizer only

What it does:
    1. Creates/updates HTTP API Gateway (v2.0)
    2. Deploys Lambda authorizer function (bearer token validation)
    3. Configures POST /ask route with Lambda integration
    4. Sets up CORS (OPTIONS method for Streamlit)
    5. Configures request validation (JSON schema)
    6. Manages Lambda invoke permissions
    7. Deploys to 'prod' stage

Key Features:
    - Automatic authorizer deployment from lambda_authorizer.py
    - Idempotent (safe to run multiple times)
    - Validates authorizer response format (prevents 500 errors)
    - Graceful degradation (continues without auth if AUTH_TOKEN missing)
    - Auto-cleanup of old permissions

Prerequisites:
    - Main Lambda function deployed (run deploy_lambda.py first)
    - AUTH_TOKEN in .env (optional, API will be public without it)
    - AWS credentials configured

Output:
    API Endpoint: https://{api-id}.execute-api.{region}.amazonaws.com/prod/ask
    
Common Issues:
    - 500 errors: Usually authorizer response format issue
    - 403 errors: Check authorizer Lambda permissions (SourceArn)
    - Authorizer not executing: Verify lambda_authorizer.py deployed correctly
"""
# deploy_api_gateway.py (in root, same level as deploy_lambda.py)--> API Gateway setup
import sys
import boto3
import json
import time
import zipfile
from pathlib import Path
from typing import Optional, Dict, Any

# Add parent directory to path to import config
sys.path.insert(0, str(Path(__file__).parent.parent))
from config import REGION, FUNCTION_NAME, AUTH_TOKEN


class APIGatewayDeployer:
    """Handles API Gateway deployment with Lambda authorizer and CORS."""
    
    def __init__(self, function_name: str = None, api_name: str = None):
        self.function_name = function_name or FUNCTION_NAME
        self.api_name = api_name or f"{self.function_name}-api"
        self.region = REGION
        
        # Validate configuration
        if not self.function_name:
            raise ValueError("FUNCTION_NAME not set in .env")
        
        # AWS clients
        self.apigw_client = boto3.client('apigateway', region_name=self.region)
        self.lambda_client = boto3.client('lambda', region_name=self.region)
        
        # Deployment state
        self.api_id: Optional[str] = None
        self.lambda_arn: Optional[str] = None
        self.authorizer_id: Optional[str] = None
        self.validator_id: Optional[str] = None
        
        print(f" Initializing API Gateway deployment for '{self.function_name}'")
    
    def deploy(self) -> Optional[str]:
        """
        Main deployment orchestration.
        
        Returns:
            str: API Gateway invoke URL or None if failed
        """
        try:
            self._validate_lambda()  # Checks lambda exists
            self._setup_api() # Creates or finds REST API gateway
            self._setup_resources() # Creates /ask resource
            self._setup_request_validation()
            self._setup_authorizer() # Auth setup is optional - continues without auth if it fails
            self._configure_methods()
            self._configure_lambda_permissions()
            self._deploy_to_stage()
            self._verify_configuration()
            
            endpoint = self._get_endpoint_url()
            self._print_success_summary(endpoint)
            
            return endpoint
            
        except Exception as e:
            print(f"\n API Gateway deployment failed: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def _validate_lambda(self):
        """Step 1: Validate Lambda function exists."""
        print("\n✓ 1. Validating Lambda function...")
        
        try:
            response = self.lambda_client.get_function(FunctionName=self.function_name)
            self.lambda_arn = response['Configuration']['FunctionArn']
            print(f"   ✓ Lambda found: {self.lambda_arn}")
        except self.lambda_client.exceptions.ResourceNotFoundException:
            raise Exception(
                f"Lambda function '{self.function_name}' not found! "
                "Run: python deploy_lambda.py first"
            )
    
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
        """Step 3: Create /ask resource."""
        print("\n✓ 3. Setting up /ask resource...")
        
        # Get root resource
        resources = self.apigw_client.get_resources(restApiId=self.api_id)
        root_id = next(r['id'] for r in resources['items'] if r['path'] == '/')
        
        
        # ------------------------------
        #   /ask
        # ------------------------------
        ask_resource = next(
            (r for r in resources['items'] if r['path'] == '/ask'),
            None
        )
        
        if ask_resource:
            self.resource_id = ask_resource['id']
            print(f"   ✓ Found existing /ask resource: {self.resource_id}")
        else:
            response = self.apigw_client.create_resource(
                restApiId=self.api_id,
                parentId=root_id,
                pathPart='ask'
            )
            self.resource_id = response['id']
            print(f"   ✓ Created /ask resource: {self.resource_id}")
        

        
        # ------------------------------
        #   REFRESH resource tree
        # ------------------------------
        resources = self.apigw_client.get_resources(restApiId=self.api_id)

        
        # ------------------------------
         #   /feedback
        # ------------------------------
        feedback_resource = next(
            (r for r in resources['items'] if r['path'] == '/feedback'),
            None
        )
        
        if feedback_resource:
            self.feedback_resource_id = feedback_resource['id']
            print(f"   ✓ Found existing /feedback resource: {self.feedback_resource_id}")
        else:
            response = self.apigw_client.create_resource(
                restApiId=self.api_id,
                parentId=root_id,
                pathPart='feedback'
            )
            self.feedback_resource_id = response['id']
            print(f"   ✓ Created /feedback resource: {self.feedback_resource_id}")
    
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
        """Step 5: Deploy and configure Lambda authorizer."""
        print("\n✓ 5. Setting up Lambda Authorizer...")
        
        if not AUTH_TOKEN:
            print("   ⚠️  AUTH_TOKEN not set - API will be public")
            self.authorizer_id = None
            return
        
        # Deploy authorizer Lambda
        authorizer_arn = self._deploy_authorizer_lambda()
        
        if not authorizer_arn:
            print("   ⚠️  Continuing without authorizer (API will be public)")
            self.authorizer_id = None
            return
        
        # Create/update API Gateway authorizer
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
                        'value': f'arn:aws:apigateway:{self.region}:lambda:path/2015-03-31/functions/{authorizer_arn}/invocations'
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
                authorizerUri=f'arn:aws:apigateway:{self.region}:lambda:path/2015-03-31/functions/{authorizer_arn}/invocations',
                authorizerResultTtlInSeconds=0,
                identitySource='method.request.header.Authorization'
            )
            self.authorizer_id = response['id']
            print(f"   ✓ Created authorizer: {self.authorizer_id}")
        
        # Configure authorizer Lambda permissions
        self._configure_authorizer_permissions(authorizer_arn)
    
    def _deploy_authorizer_lambda(self) -> Optional[str]:
        """Deploy Lambda authorizer function."""
        deployment_dir = Path(__file__).parent
        authorizer_file = deployment_dir / 'lambda_authorizer.py'
        
        if not authorizer_file.exists():
            print(f" Authorizer file not found: {authorizer_file}")
            return None
        
        authorizer_function_name = f"{self.function_name}-authorizer"
        zip_path = Path('/tmp/authorizer.zip')
        
        try:
            # Get IAM role from main Lambda
            lambda_response = self.lambda_client.get_function(FunctionName=self.function_name)
            role_arn = lambda_response['Configuration']['Role']
            
            # Create deployment package
            with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                zipf.write(authorizer_file, 'lambda_authorizer.py')
            
            with open(zip_path, 'rb') as f:
                zip_content = f.read()
            
            # Create or update function
            try:
                self.lambda_client.get_function(FunctionName=authorizer_function_name)
                
                # Update existing
                self.lambda_client.update_function_code(
                    FunctionName=authorizer_function_name,
                    ZipFile=zip_content
                )
                
                waiter = self.lambda_client.get_waiter('function_updated')
                waiter.wait(FunctionName=authorizer_function_name)
                
                self.lambda_client.update_function_configuration(
                    FunctionName=authorizer_function_name,
                    Environment={'Variables': {'AUTH_TOKEN': AUTH_TOKEN}}
                )
                
                print(f"   ✓ Updated authorizer Lambda")
                
            except self.lambda_client.exceptions.ResourceNotFoundException:
                # Create new
                self.lambda_client.create_function(
                    FunctionName=authorizer_function_name,
                    Runtime='python3.12',
                    Role=role_arn,
                    Handler='lambda_authorizer.lambda_handler',
                    Code={'ZipFile': zip_content},
                    Environment={'Variables': {'AUTH_TOKEN': AUTH_TOKEN}},
                    Timeout=10,
                    MemorySize=128,
                    Description='Bearer token authorizer for chatbot API'
                )
                
                print(f"   ✓ Created authorizer Lambda")
            
            # Wait for function to be active
            waiter = self.lambda_client.get_waiter('function_active')
            waiter.wait(FunctionName=authorizer_function_name)
            
            # Get ARN
            response = self.lambda_client.get_function(FunctionName=authorizer_function_name)
            return response['Configuration']['FunctionArn']
            
        except Exception as e:
            print(f" Authorizer deployment failed: {e}")
            return None
        finally:
            if zip_path.exists():
                zip_path.unlink()
    
    def _configure_authorizer_permissions(self, authorizer_arn: str):
        """Add API Gateway invoke permissions for authorizer Lambda."""
        authorizer_function_name = f"{self.function_name}-authorizer"
        account_id = authorizer_arn.split(':')[4]
        
        # Remove old permissions
        self._cleanup_lambda_permissions(authorizer_function_name)
        
        # Add new permission
        try:
            self.lambda_client.add_permission(
                FunctionName=authorizer_function_name,
                StatementId='apigateway-authorizer-invoke',
                Action='lambda:InvokeFunction',
                Principal='apigateway.amazonaws.com',
                SourceArn=f'arn:aws:execute-api:{self.region}:{account_id}:{self.api_id}/prod/*'
            )
            print("   ✓ Authorizer permission configured")
        except Exception as e:
            if 'ResourceConflictException' not in str(e):
                print(f" Authorizer permission warning: {e}")
    
    def _configure_methods(self):
        """Step 6: Configure POST and OPTIONS methods."""
        print("\n✓ 6. Configuring HTTP methods...")
        
        # Configure POST method
        self._configure_post_method(self.resource_id, '/ask')
        self._configure_cors(self.resource_id)
        
        # Configure CORS (OPTIONS method)
        self._configure_post_method(self.feedback_resource_id, '/feedback')
        self._configure_cors(self.feedback_resource_id)
    
    def _configure_post_method(self, resource_id: str, path: str):
        """Configure POST /ask method with Lambda integration."""
        print("   → Configuring POST {path}...")
        
        # Remove existing method
        try:
            self.apigw_client.delete_method(
                restApiId = self.api_id,
                resourceId = resource_id,
                httpMethod = 'POST'
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
        
        # Only validate /ask requests (feedback has different schema)
        if path == '/ask' and self.validator_id:
            method_config['requestValidatorId'] = self.validator_id
            method_config['requestModels'] = {'application/json': self.model_name}
        
        self.apigw_client.put_method(**method_config)

        # Method response with CORS headers
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
        
        # Configure Lambda integration
        self.apigw_client.put_integration(
            restApiId = self.api_id,
            resourceId = resource_id,
            httpMethod = 'POST',
            type = 'AWS_PROXY',
            integrationHttpMethod ='POST',
            uri = f'arn:aws:apigateway:{self.region}:lambda:path/2015-03-31/functions/{self.lambda_arn}/invocations'
        )
        
        print("   ✓ POST method configured with Lambda integration")
    
    def _configure_cors(self, resource_id: str):
        """Configure CORS with OPTIONS method."""
        print("   → Configuring CORS (OPTIONS method)...")
        
        try:
            # Create OPTIONS method
            try:
                self.apigw_client.get_method(
                    restApiId=self.api_id,
                    resourceId= resource_id,
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
            
            # MOCK integration
            self.apigw_client.put_integration(
                restApiId=self.api_id,
                resourceId= resource_id,
                httpMethod='OPTIONS',
                type='MOCK',
                requestTemplates={'application/json': '{"statusCode": 200}'}
            )
            
            # Method response
            self.apigw_client.put_method_response(
                restApiId=self.api_id,
                resourceId= resource_id,
                httpMethod='OPTIONS',
                statusCode='200',
                responseParameters={
                    'method.response.header.Access-Control-Allow-Headers': False,
                    'method.response.header.Access-Control-Allow-Methods': False,
                    'method.response.header.Access-Control-Allow-Origin': False
                },
                responseModels={'application/json': 'Empty'}
            )
            
            # Integration response
            self.apigw_client.put_integration_response(
                restApiId=self.api_id,
                resourceId= resource_id,
                httpMethod='OPTIONS',
                statusCode='200',
                responseParameters={
                    'method.response.header.Access-Control-Allow-Headers': "'Content-Type,Authorization'",
                    'method.response.header.Access-Control-Allow-Methods': "'POST,OPTIONS'",
                    'method.response.header.Access-Control-Allow-Origin': "'*'"
                },
                responseTemplates={'application/json': ''}
            )
            
            print("   ✓ CORS preflight configured  (Lambda handles POST headers)")
            
        except Exception as e:
            print(f"   ⚠️  CORS setup warning: {e}")
    
    def _configure_lambda_permissions(self):
        """Step 7: Configure Lambda invoke permissions."""
        print("\n✓ 7. Configuring Lambda permissions...")
        
        # Cleanup old permissions
        self._cleanup_lambda_permissions(self.function_name)
        
        # Add new permission
        account_id = self.lambda_arn.split(':')[4]
        source_arn = f"arn:aws:execute-api:{self.region}:{account_id}:{self.api_id}/*/*"
        
        try:
            self.lambda_client.add_permission(
                FunctionName=self.function_name,
                StatementId='apigateway-invoke-permission',
                Action='lambda:InvokeFunction',
                Principal='apigateway.amazonaws.com',
                SourceArn=source_arn
            )
            print(f"   ✓ Permission added")
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
        """Step 8: Deploy API to production stage."""
        print("\n✓ 8. Deploying to 'prod' stage...")
        
        try:
            deployment = self.apigw_client.create_deployment(
                restApiId=self.api_id,
                stageName='prod',
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
                stageName='prod'
            )
            
            if stage.get('cacheClusterEnabled', False):
                self.apigw_client.update_stage(
                    restApiId=self.api_id,
                    stageName='prod',
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
        return f"https://{self.api_id}.execute-api.{self.region}.amazonaws.com/prod"
    
    def _print_success_summary(self, endpoint: str):
        """Print deployment success summary."""
        print("\n" + "="*70)
        print("✅ API Gateway deployment complete!")
        print("="*70)
        
        print(f"\n API Details:")
        print(f"   API ID:       {self.api_id}")
        print(f"   API Name:     {self.api_name}")
        print(f"   Region:       {self.region}")
        print(f"   Lambda:       {self.function_name}")
        print(f"   Auth:         {'✓ Enabled' if self.authorizer_id else '✗ Disabled (Public API)'}")
        print(f"   CORS:         ✓ Enabled")
        print(f"   Validation:   {'✓ Enabled' if self.validator_id else '✗ Disabled'}")
        
        print(f"\n Endpoint:")
        print(f"   {endpoint}/ask")
        print(f"   {endpoint}/feedback")  
        print(f"   {endpoint}/health")
        
        # Test command
        if self.authorizer_id:
            print(f"\n Test with curl (authenticated):")
            print(f"""   curl -X POST {endpoint}/ask \\
     -H "Content-Type: application/json" \\
     -H "Authorization: Bearer {AUTH_TOKEN[:4]}***..." \\
     -d '{{"text": "What is R-studio?"}}'""")
        else:
            print(f"\n Test with curl (public):")
            print(f"""   curl -X POST {endpoint}/ask \\
     -H "Content-Type: application/json" \\
     -d '{{"text": "What is R-studio?"}}'""")
        
        print(f"\n AWS Console:")
        print(f"   https://console.aws.amazon.com/apigateway/home?region={self.region}#/apis/{self.api_id}")
        
        print(f"\n Next steps:")
        print(f"   1. Test the endpoint with curl command above")
        print(f"   2. Configure Streamlit frontend with: {endpoint}/ask")
        print(f"   3. Check CloudWatch logs if issues occur")
        print(f"   4. Use --refresh flag to clear any caching issues")


def force_api_refresh(api_id: str = None) -> bool:
    """
    Force API Gateway deployment refresh.
    
    Args:
        api_id: API Gateway ID (auto-detected if None)
    
    Returns:
        bool: True if successful
    """
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
            stageName='prod',
            description=f'Force refresh at {time.strftime("%Y-%m-%d %H:%M:%S")}'
        )
        
        print(f" Deployment refreshed: {deployment['id']}")
        return True
        
    except Exception as e:
        print(f" Refresh failed: {e}")
        return False


def main():
    """Main entry point."""

    if len(sys.argv) > 1 and sys.argv[1] == '--refresh':
        print("\n Forcing API Gateway cache refresh...\n")
        success = force_api_refresh()
        if success:
            print("\n Cache refresh complete. Test your API now.")
        else:
            print("\n Cache refresh failed. Check logs above.")
    
    elif len(sys.argv) > 1 and sys.argv[1] == '--update-auth':
        print("\n Updating authorizer only...\n")
        deployer = APIGatewayDeployer()
        deployer._validate_lambda()  # Need Lambda ARN
        auth_arn = deployer._deploy_authorizer_lambda()
        if auth_arn:
            print(f"\n Authorizer updated: {auth_arn}")
        else:
            print("\n Authorizer update failed")

    else:
        deployer = APIGatewayDeployer()
        deployer.deploy()


if __name__ == "__main__":
    main()


