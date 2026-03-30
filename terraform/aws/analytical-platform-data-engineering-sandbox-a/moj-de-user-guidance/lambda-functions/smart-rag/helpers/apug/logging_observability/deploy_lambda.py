
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
    9. Wait for deployment to stabilize
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

import boto3
import shutil
import subprocess
import json
import os
import time
from pathlib import Path
from config import KB_ID,MODEL_ID,REGION,MAX_CONTEXT_TOKENS,FUNCTION_NAME

def deploy_lambda():
    """
    Deploy Lambda function with retry logic and proper error handling.
    Waits for previous deployments to complete.
    """
    
    print(" Deploying Lambda...\n")
    
    # 0. Validate prerequisites
    print(" 0. Validating prerequisites...")
    required_files = ["lambda_handler.py", "config.py", "data/kb_catalog.json"]
    missing = [f for f in required_files if not os.path.exists(f)]
    if missing:
        print(f" Missing files: {', '.join(missing)}")
        return False
    print("   ✓ All required files present")
    
    # 1. Check if update is in progress
    print("\n 1. Checking Lambda status...")
    lambda_client = boto3.client('lambda', region_name=REGION)
    
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
                print(f" Function ready (status: {last_status})")
                break
        except Exception as e:
            print(f"  Status check warning: {e}")
            break
    
    if retry_count >= max_retries:
        print("Lambda still updating after 2.5 minutes. Try again later.")
        return False
    
    # 2. Clean build artifacts
    print("\n 2.Cleaning previous builds...")
    if os.path.exists('package'):
        shutil.rmtree('package')
    for f in ("lambda.zip", "env_config.json"):
        if os.path.exists(f):
            os.remove(f)
    os.makedirs("package/data", exist_ok=True)
    print("   ✓ Cleaned")
    
    # 2.1 Install dependencies (if requirements.txt exists)
    print("\n 2.1 Installing dependencies...")
    if os.path.exists("requirements.txt"):
        try:
            # Check if requirements.txt has content
            with open("requirements.txt", "r") as f:
                requirements = f.read().strip()
            
            if requirements:
                print(" Installing packages...")
                subprocess.check_call([
                    "pip", "install", "-r", "requirements.txt",
                    "-t", "package", 
                    "--platform", "manylinux2014_x86_64", 
                    "--only-binary=:all:",                  
                    "--python-version", "3.12", 
                    "--quiet", "--upgrade"
                ])
                print("   ✓ Dependencies installed")
            else:
                print(" No dependencies to install (empty requirements.txt)")
        except subprocess.CalledProcessError as e:
            print(f" Dependency installation warning: {e}")
            print("  Continuing with deployment...")
    else:
        print(" No requirements.txt found, skipping dependencies")
    
    # 3. Copy code
    print("\n 3.Copying code files...")
    for f in ["lambda_handler.py", "config.py"]:
        if os.path.exists(f):
            shutil.copy2(f, "package")
            print(f"   ✓ {f}")
    
    # Logging modules
    if os.path.exists("helpers"):
        shutil.copytree("helpers", "package/helpers", dirs_exist_ok=True)
        print("   ✓ helpers/")
    
    # Data
    if os.path.exists("data/kb_catalog.json"):
        shutil.copy2("data/kb_catalog.json", "package/data/kb_catalog.json")
        print("   ✓ data/kb_catalog.json")
    
    # 4. Create zip
    print("\n 4. Creating lambda.zip...")
    try:
        subprocess.check_call("cd package && zip -r -q ../lambda.zip .", shell=True)
        size_mb = os.path.getsize("lambda.zip") / 1024 / 1024
        print(f"   ✓ Package size: {size_mb:.2f} MB")
        
        # Warn if package is too large
        if size_mb > 50:
            print(f" Package is large ({size_mb:.2f} MB). Consider using Lambda layers.")
        if size_mb > 250:
            print(f" Package exceeds Lambda limit (250 MB). Deployment will fail.")
            return False
            
    except Exception as e:
        print(f"  Zip creation failed: {e}")
        return False
    """ 
    # 5. Set environment variables
    print("\n  5. Preparing environment variables...")
    env_config = {
        "Variables": {
            "KB_ID": KB_ID,            
            "MODEL_ID": MODEL_ID,           
            "AWS_REGION": REGION,                   
            "MAX_CONTEXT_TOKENS": str(MAX_CONTEXT_TOKENS),
        }
    }
    with open("env_config.json", "w") as f:
        json.dump(env_config, f, indent=2)
    print("   ✓ Config ready")
    """
    
    
    # 6. Update configuration using boto3
    print("\n 6. Updating Lambda configuration...")
    try:
        # Wait for any pending updates first
        waiter = lambda_client.get_waiter('function_updated')
        waiter.wait(FunctionName=FUNCTION_NAME)

        # ✅ USE BOTO3 for configuration
        lambda_client.update_function_configuration(
            FunctionName=FUNCTION_NAME,
            Handler='lambda_handler.lambda_handler',
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
        print("   ✓ Configuration updated")
        
        # Wait for configuration update to complete
        print(" Waiting for configuration update...")
        waiter.wait(FunctionName=FUNCTION_NAME)
        print("   ✓ Configuration active")
        
    except Exception as e:
        print(f" Config update warning: {e}")
        print("   Continuing with code upload...")
    
    # 7. Upload code using subprocess (better for large files)
    print("\n 7. Uploading code to Lambda...")
    upload_retry = 0
    max_upload_retries = 3
    
    while upload_retry < max_upload_retries:
        try:
            # ✅ USE SUBPROCESS for file upload (more efficient)
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
                print(f" Upload failed, retrying ({upload_retry}/{max_upload_retries})...")
                time.sleep(15)
            else:
                print(f" Upload failed after {max_upload_retries} attempts: {e}")
                return False
    
    
    # 8. Wait for deployment to stabilize
    print("\n 8. Waiting for deployment to stabilize...")
    time.sleep(5)
    
    # Verify deployment
    try:
        response = lambda_client.get_function(FunctionName=FUNCTION_NAME)
        state = response['Configuration'].get('State', 'Unknown')
        last_update_status = response['Configuration'].get('LastUpdateStatus', 'Unknown')
        
        print(f"   ✓ Function State: {state}")
        print(f"   ✓ Last Update Status: {last_update_status}")
        
        if state != 'Active' or last_update_status == 'Failed':
            print(f" Deployment may have issues. Check AWS Console.")
            
    except Exception as e:
        print(f" Could not verify deployment: {e}")
    
    # 9. Cleanup temporary files
    print("\n 9.Cleaning up temporary files...")
    try:
        if os.path.exists('package'):
            shutil.rmtree('package')
        if os.path.exists('lambda.zip'):
            os.remove('lambda.zip')
        if os.path.exists('env_config.json'):
            os.remove('env_config.json')
        print(" Cleanup complete")
    except Exception as e:
        print(f" Cleanup warning: {e}")
    
    # 10. Summary
    print("\n" + "="*60)
    print("Deployment complete!")
    print("="*60)
    print(f"\n Deployment Summary:")
    print(f"   Function: {FUNCTION_NAME}")
    print(f"   Region: {REGION}")
    print(f"   Package Size: {size_mb:.2f} MB")
    print(f"   Handler: lambda_handler.lambda_handler")
    print(f"   Timeout: 60s")
    print(f"   Memory: 512 MB")
    print("\n Next steps:")
    print("  1. Wait 30 seconds for cold start")
    print('  2. Test: ask_lambda("What is RAG?")')
    print(f"  3. Check logs: https://console.aws.amazon.com/cloudwatch/home?region={REGION}#logsV2:log-groups/log-group/$252Faws$252Flambda$252F{FUNCTION_NAME}")
    print("\n Tip: Run deploy_lambda() again to update code after changes")
    
    return True