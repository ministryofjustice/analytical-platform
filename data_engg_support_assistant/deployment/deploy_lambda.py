"""
Lambda Deployment Script for Smart RAG Pipeline

This script automates the deployment of the Smart RAG Lambda function to AWS.
It handles the complete deployment lifecycle including dependency installation,
code packaging, environment configuration, and deployment verification.

Deployment Steps:
    1. Validate prerequisites (lambda_handler.py, config.py, kb_catalog.json)
    2. Check Lambda status and wait for any in-progress updates
    3. Clean previous build artifacts (package/, lambda.zip)
    4. Install Python dependencies from requirements.txt
    5. Copy application code (lambda_handler.py, helpers/, data/)
    6. Create deployment package (lambda.zip)
    7. Update Lambda configuration (environment variables, timeout, memory) <- boto3 with waiter
    8. Upload code to Lambda with retry logic  <- subprocess with AWS CLI, it is better for larger files(>10mb), boto3 will be clunky for large files
    9. Wait for deployment to stabilise
    10. Verify deployment status
    11. Cleanup temporary files
    12. summary

Prerequisites:
    - AWS credentials configured (via ~/.aws/credentials or environment)
    - Lambda function already created in AWS (use AWS Console or IaC)
    - Required files present: lambda_handler.py, config.py, data/kb_catalog.json
    - AWS CLI installed (for deployment commands)

Configuration (from config.py):
    - FUNCTION_NAME: Name of Lambda function in AWS
    - REGION: AWS region where Lambda is deployed
    - KB_ID: Knowledge Base ID for RAG pipeline
    - MODEL_ID: Bedrock model ID
    - MAX_CONTEXT_TOKENS: Token limit for context window

Usage:
    from helpers.apug.logging_observability.deploy_lambda import deploy_lambda
    
    # Deploy to AWS
    success = deploy_lambda()
    
    if success:
        print("Ready to test!")

Notes:
    - First deployment may take 2-3 minutes
    - Subsequent deployments faster (~30-60 seconds)
    - Lambda will have 30-second cold start on first invocation
    - Check CloudWatch logs if deployment succeeds but function fails
    - Package size limit: 250 MB (use Lambda layers if exceeded)

Troubleshooting:
    - "Update in progress": Wait 30 seconds and run again
    - "Package too large": Move dependencies to Lambda layer
    - "Permission denied": Check IAM role has Bedrock + KB permissions
    - "Function not found": Create Lambda function in AWS Console first
"""

# Design decisions are:
# Hybrid approach: boto3 for config, subprocess for upload( boto3 can be clunky for large files, subprocess with AWS CLI is more efficient for uploads)
# Retry logic: Waits if Lambda is updating
# Size checks: warns if >50 MB, blocks if > 250 MB --> we probably have to change 

# This code still need to verfiy IAM role check, Fails if Lambda missing Bedrock permissions. Adding role validation will help.
# Does subprocess requires AWS CLI?

# deploy_lambda.py --> Lambda deployment
import os
import sys
import time
import zipfile
import boto3
import shutil
import platform
import subprocess
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))
from config import KB_ID,MODEL_ID,REGION,MAX_CONTEXT_TOKENS,FUNCTION_NAME, LAYER_NAME

# ================== Bedrock permissions fro Lambda execution role====================
def ensure_bedrock_permissions(lambda_client, function_name):
    """
    Ensure Bedrock permissions are attached to Lambda role
    
    Lambda deployments succeed but fail at runtime because Bedrock permissions 
    aren't automatically attached to the Lambda execution role, requiring manual 
    attach-role-policy command each time you redeploy.

    """
    import boto3
    
    try:
        # Get Lambda's execution role
        response = lambda_client.get_function(FunctionName=function_name)
        role_arn = response['Configuration']['Role']
        role_name = role_arn.split('/')[-1]
        
        # Attach Bedrock policy
        iam = boto3.client('iam')
        iam.attach_role_policy(
            RoleName=role_name,
            PolicyArn='arn:aws:iam::aws:policy/AmazonBedrockFullAccess'
        )
        print("   ✓ Bedrock permissions attached")
        return True
        
    except iam.exceptions.NoSuchEntityException:
        print(f"   ⚠️  Role not found: {role_name}")
        return False
        
    except Exception as e:
        if 'already attached' in str(e).lower() or 'entityalreadyexists' in str(e).lower():
            print("   ✓ Bedrock permissions already attached")
            return True
        else:
            print(f"   ⚠️  Permission error: {e}")
            return False


# ================== DynamoDB permissions for Lambda execution role====================
def ensure_dynamodb_permissions(lambda_client, function_name):
    """
    Ensure DynamoDB permissions are attached to Lambda role for conversation logging
    
    Allows Lambda to write conversation logs to the RAG-ConversationLogs table.
    """
    import boto3
    import json
    
    try:
        # Get Lambda's execution role
        response = lambda_client.get_function(FunctionName=function_name)
        role_arn = response['Configuration']['Role']
        role_name = role_arn.split('/')[-1]
        
        # Create inline policy for DynamoDB
        iam = boto3.client('iam')
        policy_name = 'RAGDynamoDBConversationLogging'
        
        dynamodb_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "dynamodb:PutItem",
                        "dynamodb:UpdateItem",
                        "dynamodb:GetItem",
                        "dynamodb:Query",
                        "dynamodb:DescribeTable"
                    ],
                    "Resource": [
                        f"arn:aws:dynamodb:{REGION}:*:table/RAG-ConversationLogs",
                        f"arn:aws:dynamodb:{REGION}:*:table/RAG-ConversationLogs/index/*"
                    ]
                }
            ]
        }
        
        iam.put_role_policy(
            RoleName=role_name,
            PolicyName=policy_name,
            PolicyDocument=json.dumps(dynamodb_policy)
        )
        print("   ✓ DynamoDB permissions attached")
        return True
        
    except iam.exceptions.NoSuchEntityException:
        print(f"   ⚠️  Role not found: {role_name}")
        return False
        
    except Exception as e:
        if 'no changes' in str(e).lower():
            print("   ✓ DynamoDB permissions already attached")
            return True
        else:
            print(f"   ⚠️  DynamoDB permission error: {e}")
            return False



# ==================== LAYER CONFIGURATION ====================
LAYER_ARN = None
def deploy_lambda():
    """
    Deploy Lambda function with Lambda Layers.
    Dependencies are in the layer, only code is uploaded.
    """
    
    print("="*80)
    print("DEPLOYING LAMBDA FUNCTION (WITH LAYERS)")
    print("="*80)
    print(" Deploying Lambda...\n")

    # ==================== STEP 0.1: AWS CLI VALIDATION ====================
    print("✓ 0.1 Validating AWS CLI...")
    try:
        subprocess.check_output(["aws", "--version"], stderr=subprocess.STDOUT)
        print("   ✓ AWS CLI found")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(" AWS CLI not found!")
        print("\n Install it:")
        print("   - Mac: brew install awscli")
        print("   - Windows: https://aws.amazon.com/cli/")
        print("   - Linux: sudo apt install awscli")
        print("\n Then configure: aws configure")
        return False

    # ==================== STEP 0.2: AWS CREDENTIALS ====================
    print("\n✓ 0.2 Validating AWS credentials...")
    try:
        sts = boto3.client('sts')
        identity = sts.get_caller_identity()
        ACCOUNT_ID = identity['Account']
        print(f"   ✓ AWS Account: {ACCOUNT_ID}")
        print(f"   ✓ Region: {REGION}")
    except Exception as e:
        print(f" AWS credentials issue: {e}")
        print("   Run: aws configure")
        return False

    # ==================== STEP 0.3: CONFIG VALIDATION ====================
    print("\n✓ 0.3 Validating configuration...")
    if not FUNCTION_NAME:
        print(" FUNCTION_NAME not set in .env")
        return False
    if not KB_ID or not MODEL_ID:
        print(" KB_ID or MODEL_ID not set in .env")
        return False
    
    # ==================== STEP 0.4: FILE VALIDATION ====================
    print("\n✓ 0.4 Validating prerequisites...")
    required_files = ["lambda_handler.py", "config.py", "data/kb_catalog.json"]
    missing = [f for f in required_files if not os.path.exists(f)]
    if missing:
        print(f" Missing files: {', '.join(missing)}")
        return False
    print("   ✓ All required files present")

    # ==================== STEP 1: LAMBDA EXISTS CHECK ====================
    print("\n✓ 1. Checking if Lambda function exists...")
    lambda_client = boto3.client('lambda', region_name=REGION)

    try:
        lambda_client.get_function(FunctionName=FUNCTION_NAME)
        print(f"   ✓ Function exists: {FUNCTION_NAME}")
    except lambda_client.exceptions.ResourceNotFoundException:
        print(f" Function '{FUNCTION_NAME}' does not exist!")
        print("\n Create it first:")
        print(f"   1. Go to AWS Console > Lambda")
        print(f"   2. Create function named: {FUNCTION_NAME}")
        print(f"   3. Runtime: Python 3.12")
        print(f"   4. Attach role with:")
        print(f"      - AWSLambdaBasicExecutionRole")
        print(f"      - BedrockFullAccess (or custom Bedrock policy)")
        return False
   
    # ==================== STEP 1.5: STATUS CHECK ====================
    print("\n✓ 1.5 Checking Lambda status...")
    max_retries = 5
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            response = lambda_client.get_function(FunctionName=FUNCTION_NAME)
            last_status = response['Configuration'].get('LastUpdateStatus', 'Successful')
            
            if last_status == 'InProgress':
                print(f" Update in progress... waiting (attempt {retry_count + 1}/{max_retries})")
                time.sleep(30)
                retry_count += 1
            else:
                print(f"   ✓ Function ready (status: {last_status})")
                break
        except Exception as e:
            print(f"  Status check warning: {e}")
            break
    
    if retry_count >= max_retries:
        print(" Lambda still updating after 2.5 minutes. Try again later.")
        return False
    
    # ==================== STEP 2: SETUP BUILD ENVIRONMENT ====================
    print("\n✓ 2. Setting up build environment...")
    project_root = Path(__file__).parent.parent
    package_dir = Path('package')
    zip_path = Path('lambda.zip')

    # Clean old artifacts
    if package_dir.exists():
        shutil.rmtree(package_dir)
        print("   ✓ Cleaned old package/ directory")
    
    if zip_path.exists():
        zip_path.unlink()
        print("   ✓ Cleaned old lambda.zip")

    package_dir.mkdir(parents=True)
    print(f"   ✓ Created fresh package directory")

    # ==================== STEP 3: SKIP DEPENDENCIES (USING LAYER) ====================
    print("\n✓ 3. Dependency strategy: Lambda Layer")
    print("   → Skipping pip install (dependencies provided by layer)")
    print(" If layer doesn't exist, run: python deployment/create_lambda_layer.py")
    
    # ==================== STEP 4: COPY CODE FILES ====================
    print("\n✓ 4. Copying application code...")
    
    # Copy main files
    for f in ["lambda_handler.py", "config.py"]:
        if os.path.exists(f):
            shutil.copy2(f, package_dir)
            print(f"   ✓ {f}")
    
    # Copy helpers directory
    if os.path.exists("helpers"):
        shutil.copytree("helpers", package_dir / "helpers", dirs_exist_ok=True)
        print("   ✓ helpers/")
    
    # Copy data files
    if os.path.exists("data/kb_catalog.json"):
        (package_dir / "data").mkdir(exist_ok=True)
        shutil.copy2("data/kb_catalog.json", package_dir / "data/kb_catalog.json")
        print("   ✓ data/kb_catalog.json")
    
    # Calculate code-only size
    code_size = sum(f.stat().st_size for f in package_dir.rglob('*') if f.is_file())
    print(f"   ✓ Code size: {code_size / (1024*1024):.2f} MB")
    
    # ==================== STEP 5: CREATE ZIP ====================
    print("\n✓ 5. Creating deployment package...")
    
    try:
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for file_path in package_dir.rglob('*'):
                if file_path.is_file():
                    arcname = file_path.relative_to(package_dir)
                    zipf.write(file_path, arcname)
        
        size_mb = zip_path.stat().st_size / (1024 * 1024)
        print(f"   ✓ Package size: {size_mb:.2f} MB")
        
        if size_mb > 50:
            print(f"  Package is large ({size_mb:.2f} MB)")
            print(f"   → Make sure you're not including dependencies!")
        if size_mb > 250:
            print(f"  Package exceeds Lambda limit (250 MB)")
            return False
            
    except Exception as e:
        print(f" Zip creation failed: {e}")
        return False
      
    # ==================== STEP 6: UPDATE CONFIGURATION WITH LAYER ====================
    print("\n✓ 6. Updating Lambda configuration...")
    try:
        # Wait for any pending updates
        waiter = lambda_client.get_waiter('function_updated')
        waiter.wait(FunctionName=FUNCTION_NAME)

        # Build configuration
        config_params = {
            'FunctionName': FUNCTION_NAME,
            'Handler': 'lambda_handler.lambda_handler',
            'Timeout': 30,
            'MemorySize': 512,
            'Environment': {
                'Variables': {
                    'KB_ID': KB_ID,
                    'MODEL_ID': MODEL_ID,
                    'MAX_CONTEXT_TOKENS': str(MAX_CONTEXT_TOKENS),
                    'DYNAMODB_TABLE_NAME': 'RAG-ConversationLogs'
                }
            }
        }
        
        # ==================== LAYER DETECTION/ATTACHMENT ====================
        layer_to_use = LAYER_ARN
        
        if not layer_to_use:
            # Auto-detect latest layer version
            print("   → No LAYER_ARN set, detecting latest layer...")
            try:
                layers = lambda_client.list_layer_versions(
                    LayerName= LAYER_NAME,
                    CompatibleRuntime='python3.12'
                )
                if layers['LayerVersions']:
                    layer_to_use = layers['LayerVersions'][0]['LayerVersionArn']
                    print(f"   ✓ Found layer: {layer_to_use}")
                else:
                    print("   ⚠️  No layer found!")
                    layer_to_use = None
            except lambda_client.exceptions.ResourceNotFoundException:
                print("   ⚠️  Layer 'smart-rag-dependencies' does not exist!")
                layer_to_use = None
        
        # ==================== BLOCK DEPLOYMENT IF NO LAYER ====================
        if not layer_to_use:
            print("\n" + "="*80)
            print(" DEPLOYMENT BLOCKED: Lambda Layer Required")
            print("="*80)
            print("\n Why layers are required:")
            print("   • Lambda layers provide dependencies (boto3, langchain, etc.)")
            print("   • Without layers, Lambda will crash with ImportError")
            print("   • Layers keep deployment package small and fast")
            print("\n What happens without a layer:")
            print("   ✅ Deployment succeeds")
            print("    First request fails with: ModuleNotFoundError: No module named 'langchain'")
            print("    All subsequent requests fail")
            print("\n How to fix:")
            print("   1. Create layer:")
            print("      python deployment/create_lambda_layer.py")
            print("")
            print("   2. Wait for completion (~3-5 minutes)")
            print("")
            print("   3. Re-run this deployment:")
            print("      python deployment/deploy_lambda.py")
            print("\n Advanced options:")
            print("   • Set LAYER_ARN in deploy_lambda.py to use specific version")
            print("   • Check existing layers:")
            print(f"      aws lambda list-layer-versions --layer-name smart-rag-dependencies --region {REGION}")
            print("\n" + "="*80)
            
            # Cleanup before exit
            if package_dir.exists():
                shutil.rmtree(package_dir)
            if zip_path.exists():
                zip_path.unlink()
            
            return False  #  Block deployment
        
        # ==================== LAYER FOUND - ATTACH IT ====================
        # If we reach here, layer_to_use is guaranteed to be set
        config_params['Layers'] = [layer_to_use]
        
        layer_version = layer_to_use.split(':')[-1]
        print(f"   ✓ Attaching layer version {layer_version}")
        
        # Update configuration
        lambda_client.update_function_configuration(**config_params)
        print("   ✓ Configuration updated")
        
        # Wait for update to complete
        print("   → Waiting for configuration update...")
        waiter.wait(FunctionName=FUNCTION_NAME)
        print("   ✓ Configuration active")

        # ==================== ENSURE BEDROCK PERMISSIONS ====================
        print("   → Checking Bedrock permissions...")
        ensure_bedrock_permissions(lambda_client, FUNCTION_NAME)
        
        # ==================== ENSURE DYNAMODB PERMISSIONS ====================
        print("   → Checking DynamoDB permissions...")
        ensure_dynamodb_permissions(lambda_client, FUNCTION_NAME)
        
    except Exception as e:
        print(f"\n Configuration update failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    # ==================== STEP 7: UPLOAD CODE ====================
    print("\n✓ 7. Uploading code to Lambda...")
    upload_retry = 0
    max_upload_retries = 3
    
    while upload_retry < max_upload_retries:
        try:
            # Direct upload (should be fast since no dependencies)
            subprocess.check_call([
                "aws", "lambda", "update-function-code",
                "--function-name", FUNCTION_NAME,
                "--zip-file", "fileb://lambda.zip",
                "--region", REGION
            ])
            print("   ✓ Code uploaded successfully")
            break
        except subprocess.CalledProcessError as e:
            upload_retry += 1
            if upload_retry < max_upload_retries:
                print(f"  Upload failed, retrying ({upload_retry}/{max_upload_retries})...")
                time.sleep(15)
            else:
                print(f" Upload failed after {max_upload_retries} attempts: {e}")
                return False
    
    # ==================== STEP 8: VERIFY DEPLOYMENT ====================
    print("\n✓ 8. Verifying deployment...")
    time.sleep(5)
    
    try:
        response = lambda_client.get_function(FunctionName=FUNCTION_NAME)
        state = response['Configuration'].get('State', 'Unknown')
        last_update_status = response['Configuration'].get('LastUpdateStatus', 'Unknown')
        layers = response['Configuration'].get('Layers', [])
        
        print(f"   ✓ Function State: {state}")
        print(f"   ✓ Last Update Status: {last_update_status}")
        print(f"   ✓ Layers Attached: {len(layers)}")
        
        if layers:
            for layer in layers:
                print(f"      - {layer['Arn']}")
        else:
            print("   ⚠️  WARNING: No layers attached!")
        
        if state != 'Active' or last_update_status == 'Failed':
            print(f"   ⚠️  Deployment may have issues. Check AWS Console.")
            
    except Exception as e:
        print(f"   ⚠️  Could not verify deployment: {e}")
    
    # ==================== STEP 9: CLEANUP ====================
    print("\n✓ 9. Cleaning up temporary files...")
    try:
        if package_dir.exists():
            shutil.rmtree(package_dir)
        if zip_path.exists():
            zip_path.unlink()
        print("   ✓ Cleanup complete")
    except Exception as e:
        print(f"   ⚠️  Cleanup warning: {e}")
    
    # ==================== SUCCESS SUMMARY ====================
    print("\n" + "="*80)
    print("✅ DEPLOYMENT COMPLETE!")
    print("="*80)
    print(f"\n Deployment Summary:")
    print(f"   Function: {FUNCTION_NAME}")
    print(f"   Region: {REGION}")
    print(f"   Code Size: {size_mb:.2f} MB (without dependencies)")
    print(f"   Handler: lambda_handler.lambda_handler")
    print(f"   Timeout: 30s")
    print(f"   Memory: 512 MB")
    print(f"   Layers: {len(layers) if 'layers' in locals() else 'Unknown'}")
    
    print("\n Next Steps:")
    print("   1. Deploy API Gateway: python deployment/deploy_api_gateway.py")
    print("   2. Test endpoint with curl")
    print(f"   3. Check logs: https://console.aws.amazon.com/cloudwatch/home?region={REGION}#logsV2:log-groups/log-group/$252Faws$252Flambda$252F{FUNCTION_NAME}")
    
    if not layer_to_use:
        print("\n  IMPORTANT: No layer attached!")
        print("   → Run: python deployment/create_lambda_layer.py")
    
    return True


if __name__ == "__main__":
    success = deploy_lambda()
    sys.exit(0 if success else 1)




"""
deployment/
├── deploy_lambda.py           # Creates Main Lambda + IAM + layers + config
├── deploy_api_gateway.py      # Creates API Gateway + Authorizer Lambda --> Terraform
├── lambda_authorizer.py       # Authorizer source code (Unchanged code)
├── create_lambda_layer.py     # Builds layer (Unchanged code)
├── setup_dynamodb.py          # Creates DynamoDB --> Terraform
└── setup_guardrails.py        # Creates Guardrails --> Terraform


Lambda Code Deployment Script

Infrastructure (IAM, config, layers) managed by Terraform.
This script ONLY uploads code for faster iteration.

Usage:
    python deployment/deploy_lambda.py              # Deploy both
    python deployment/deploy_lambda.py --main-only  # Main Lambda only
    python deployment/deploy_lambda.py --authorizer-only  # Authorizer only

Prerequisites:
    1. Terraform apply completed: cd terraform/environments/dev && terraform apply
    2. Lambda layer exists: python deployment/create_lambda_layer.py
    3. AWS CLI configured: aws configure


import os
import sys
import shutil
import zipfile
import subprocess
import argparse
from pathlib import Path

from dotenv import load_dotenv
load_dotenv()

# Configuration - must match Terraform naming
REGION = os.getenv('AWS_REGION', 'eu-west-2')
PROJECT_NAME = os.getenv('PROJECT_NAME', 'smartrag')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'dev')

# Function names (match Terraform: ${project_name}-${environment}-smart-rag)
MAIN_FUNCTION_NAME = os.getenv('FUNCTION_NAME', f'{PROJECT_NAME}-{ENVIRONMENT}-smart-rag')
AUTHORIZER_FUNCTION_NAME = os.getenv('AUTHORIZER_FUNCTION_NAME', f'{MAIN_FUNCTION_NAME}-authorizer')


def verify_lambda_exists(function_name: str) -> bool:
    #Verify Lambda function exists (created by Terraform).
    try:
        result = subprocess.run(
            ["aws", "lambda", "get-function",
             "--function-name", function_name,
             "--region", REGION],
            capture_output=True, text=True
        )
        return result.returncode == 0
    except Exception:
        return False


def deploy_main_lambda() -> bool:
    
    #Deploy main RAG Lambda code.
    
    #Returns:
    #    bool: True if successful
    
    print("\n" + "=" * 60)
    print("MAIN LAMBDA")
    print("=" * 60)
    
    # ==================== STEP 1: Validate required source files ====================
    required_files = ["lambda_handler.py", "config.py"]
    missing = [f for f in required_files if not os.path.exists(f)]
    if missing:
        print(f"❌ Missing files: {', '.join(missing)}")
        print(f"   Current directory: {os.getcwd()}")
        return False
    
    # ==================== STEP 2: Prepare build directory ====================
    package_dir = Path('package')
    zip_path = Path('lambda.zip')
    
    if package_dir.exists():
        shutil.rmtree(package_dir)
    if zip_path.exists():
        zip_path.unlink()
    
    package_dir.mkdir(parents=True)
    print("✓ Build directory ready")
    
    # ==================== STEP 3: Copy files ====================
    print("✓ Copying files...")
    for f in ["lambda_handler.py", "config.py"]:
        if os.path.exists(f):
            shutil.copy2(f, package_dir)
            print(f"   - {f}")
    
    if os.path.exists("helpers"):
        shutil.copytree("helpers", package_dir / "helpers", dirs_exist_ok=True)
        print("   - helpers/")
    
    if os.path.exists("data/kb_catalog.json"):
        (package_dir / "data").mkdir(exist_ok=True)
        shutil.copy2("data/kb_catalog.json", package_dir / "data/kb_catalog.json")
        print("   - data/kb_catalog.json")
    
    # ==================== STEP 4: Create ZIP ====================
    print("✓ Creating ZIP...")
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file_path in package_dir.rglob('*'):
            if file_path.is_file():
                arcname = file_path.relative_to(package_dir)
                zipf.write(file_path, arcname)
    
    size_mb = zip_path.stat().st_size / (1024 * 1024)
    print(f"   Package size: {size_mb:.2f} MB")
    
    # ==================== STEP 5: Verify ZIP ====================
    print("✓ Verifying ZIP...")
    with zipfile.ZipFile(zip_path, 'r') as zipf:
        if 'lambda_handler.py' not in zipf.namelist():
            print("❌ lambda_handler.py not at root of ZIP!")
            return False
        print("   lambda_handler.py at root ✓")
    
    # ==================== STEP 6: Upload to AWS ====================
    print(f"✓ Uploading to {MAIN_FUNCTION_NAME}...")
    try:
        subprocess.check_call([
            "aws", "lambda", "update-function-code",
            "--function-name", MAIN_FUNCTION_NAME,
            "--zip-file", "fileb://lambda.zip",
            "--region", REGION
        ], stdout=subprocess.DEVNULL)
        print("   ✅ Upload successful")
        success = True
    except subprocess.CalledProcessError as e:
        print(f"   ❌ Upload failed: {e}")
        success = False
    
    # ==================== STEP 7: Cleanup ====================
    if package_dir.exists():
        shutil.rmtree(package_dir)
    if zip_path.exists():
        zip_path.unlink()
    
    return success


def deploy_authorizer() -> bool:
    
    #Deploy authorizer Lambda code.
    
    #Returns:
    #    bool: True if successful
    
    print("\n" + "=" * 60)
    print("AUTHORIZER LAMBDA")
    print("=" * 60)
    
    # ==================== STEP 1: Validate source file ====================
    source_file = Path("deployment/lambda_authorizer.py")
    zip_path = Path('authorizer.zip')
    
    if not source_file.exists():
        print(f"❌ {source_file} not found!")
        print(f"   Current directory: {os.getcwd()}")
        return False
    print(f"✓ Found: {source_file}")
    
    # ==================== STEP 2: Cleanup old ZIP ====================
    if zip_path.exists():
        zip_path.unlink()
    
    # ==================== STEP 3: Create ZIP ====================
    print("✓ Creating ZIP...")
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(source_file, "lambda_authorizer.py")
    
    size_kb = zip_path.stat().st_size / 1024
    print(f"   Package size: {size_kb:.2f} KB")
    
    # ==================== STEP 4: Verify ZIP ====================
    print("✓ Verifying ZIP...")
    with zipfile.ZipFile(zip_path, 'r') as zipf:
        files = zipf.namelist()
        print(f"   Files: {files}")
        if 'lambda_authorizer.py' not in files:
            print("❌ lambda_authorizer.py not at root of ZIP!")
            return False
        if any('/' in f for f in files):
            print("❌ Files are nested (should be at root)!")
            return False
        print("   lambda_authorizer.py at root ✓")
    
    # ==================== STEP 5: Upload to AWS ====================
    print(f"✓ Uploading to {AUTHORIZER_FUNCTION_NAME}...")
    try:
        subprocess.check_call([
            "aws", "lambda", "update-function-code",
            "--function-name", AUTHORIZER_FUNCTION_NAME,
            "--zip-file", "fileb://authorizer.zip",
            "--region", REGION
        ], stdout=subprocess.DEVNULL)
        print("   ✅ Upload successful")
        success = True
    except subprocess.CalledProcessError as e:
        print(f"   ❌ Upload failed: {e}")
        success = False
    
    # ==================== STEP 6: Cleanup ====================
    if zip_path.exists():
        zip_path.unlink()
    
    return success


def main():
    #Main deployment function with CLI options.
    parser = argparse.ArgumentParser(
        description='Deploy Lambda code (infrastructure managed by Terraform)'
    )
    parser.add_argument(
        '--main-only',
        action='store_true',
        help='Deploy only the main RAG Lambda'
    )
    parser.add_argument(
        '--authorizer-only',
        action='store_true',
        help='Deploy only the authorizer Lambda'
    )
    parser.add_argument(
        '--skip-verify',
        action='store_true',
        help='Skip Lambda existence verification'
    )
    
    args = parser.parse_args()
    
    # ========== Display deployment context ==========
    print("=" * 60)
    print("LAMBDA CODE DEPLOYMENT")
    print("=" * 60)
    print(f"Region:      {REGION}")
    print(f"Project:     {PROJECT_NAME}")
    print(f"Environment: {ENVIRONMENT}")
    print(f"Main Lambda: {MAIN_FUNCTION_NAME}")
    print(f"Authorizer:  {AUTHORIZER_FUNCTION_NAME}")
    print("\nℹ️  Infrastructure managed by Terraform")
    print("ℹ️  This script only uploads code")
    
    # ========== Pre-flight: Verify functions exist ==========
    if not args.skip_verify:
        print("\n✓ Verifying Lambda functions exist...")
        
        if not args.authorizer_only:
            if not verify_lambda_exists(MAIN_FUNCTION_NAME):
                print(f"❌ {MAIN_FUNCTION_NAME} not found!")
                print("   Run: cd terraform/environments/dev && terraform apply")
                return False
            print(f"   ✓ {MAIN_FUNCTION_NAME}")
        
        if not args.main_only:
            if not verify_lambda_exists(AUTHORIZER_FUNCTION_NAME):
                print(f"❌ {AUTHORIZER_FUNCTION_NAME} not found!")
                print("   Run: cd terraform/environments/dev && terraform apply")
                return False
            print(f"   ✓ {AUTHORIZER_FUNCTION_NAME}")
    
    # ========== Execute deployment ==========
    results = {}
    
    if args.authorizer_only:
        results['authorizer'] = deploy_authorizer()
    elif args.main_only:
        results['main'] = deploy_main_lambda()
    else:
        results['main'] = deploy_main_lambda()
        results['authorizer'] = deploy_authorizer()
    
    # ========== Summary ==========
    print("\n" + "=" * 60)
    print("DEPLOYMENT SUMMARY")
    print("=" * 60)
    
    all_success = True
    for name, success in results.items():
        status = "✅" if success else "❌"
        func_name = MAIN_FUNCTION_NAME if name == 'main' else AUTHORIZER_FUNCTION_NAME
        print(f"   {status} {name}: {func_name}")
        if not success:
            all_success = False
    
    if all_success:
        print("\n✅ All deployments successful!")
        print(f"\n📋 View logs:")
        print(f"   https://{REGION}.console.aws.amazon.com/cloudwatch/home?region={REGION}#logsV2:log-groups")
    else:
        print("\n❌ Some deployments failed. Check errors above.")
    
    return all_success


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

"""