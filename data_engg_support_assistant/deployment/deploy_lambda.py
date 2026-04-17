""" 
Lambda Code Deployment Script for terraform-managed infrastructure 

Terraform manages:
- Lambda function creation
- IAM roles and permissions
- Environment variables
- Layer attachment

This script only:
- Packages application code
- Uploads to existing Lambda function

This script ONLY uploads code for faster iteration.

Usage:
    python deployment/deploy_lambda.py              # Deploy both
    python deployment/deploy_lambda.py --main-only  # Main Lambda only
    python deployment/deploy_lambda.py --authorizer-only  # Authorizer only

Prerequisites:
    1. Terraform apply completed: cd terraform/environments/dev && terraform apply
    2. Lambda layer exists: python deployment/create_lambda_layer.py
    3. AWS CLI configured: aws configure

deployment/
├── deploy_lambda.py           # Creates Main Lambda + IAM + layers + config
├── deploy_api_gateway.py      # Creates API Gateway + Authorizer Lambda --> Terraform
├── lambda_authorizer.py       # Authorizer source code (Unchanged code)
├── create_lambda_layer.py     # Builds layer (Unchanged code)
├── setup_dynamodb.py          # Creates DynamoDB --> Terraform
└── setup_guardrails.py        # Creates Guardrails --> Terraform

"""
import os
import sys
import shutil
import zipfile
import subprocess
import argparse
from pathlib import Path

from dotenv import load_dotenv
load_dotenv()

# ==================== CONFIGURATION ====================
REGION = os.getenv('AWS_REGION', 'eu-west-2')
PROJECT_NAME = os.getenv('PROJECT_NAME', 'moj-de-user-guidance')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'dev')

# Function names (match Terraform naming)
MAIN_FUNCTION_NAME = os.getenv('FUNCTION_NAME', f'{PROJECT_NAME}-{ENVIRONMENT}-smart-rag')
AUTHORIZER_FUNCTION_NAME = os.getenv('AUTHORIZER_FUNCTION_NAME', f'{PROJECT_NAME}-{ENVIRONMENT}-smart-rag-authorizer')


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
        print(f" Missing files: {', '.join(missing)}")
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
            if file_path.is_file() and '__pycache__' not in str(file_path): # Exclude __pycache__
                arcname = file_path.relative_to(package_dir)
                zipf.write(file_path, arcname)
    
    size_mb = zip_path.stat().st_size / (1024 * 1024)
    print(f"   Package size: {size_mb:.2f} MB")
    
    # ==================== STEP 5: Verify ZIP ====================
    print("✓ Verifying ZIP...")
    with zipfile.ZipFile(zip_path, 'r') as zipf:
        if 'lambda_handler.py' not in zipf.namelist():
            print(" lambda_handler.py not at root of ZIP!")
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
        print(" Upload successful")
        success = True
    except subprocess.CalledProcessError as e:
        print(f" Upload failed: {e}")
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
        print(f" {source_file} not found!")
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
            print(" lambda_authorizer.py not at root of ZIP!")
            return False
        if any('/' in f for f in files):
            print(" Files are nested (should be at root)!")
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
        print(" Upload successful")
        success = True
    except subprocess.CalledProcessError as e:
        print(f" Upload failed: {e}")
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
    print("\n  Infrastructure managed by Terraform")
    print("  This script only uploads code")
    
    # ========== Pre-flight: Verify functions exist ==========
    if not args.skip_verify:
        print("\n✓ Verifying Lambda functions exist...")
        
        if not args.authorizer_only:
            if not verify_lambda_exists(MAIN_FUNCTION_NAME):
                print(f" {MAIN_FUNCTION_NAME} not found!")
                print("   Run: cd terraform/environments/dev && terraform apply")
                return False
            print(f"   ✓ {MAIN_FUNCTION_NAME}")
        
        if not args.main_only:
            if not verify_lambda_exists(AUTHORIZER_FUNCTION_NAME):
                print(f" {AUTHORIZER_FUNCTION_NAME} not found!")
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
        print(f"\n View logs:")
        print(f"   https://{REGION}.console.aws.amazon.com/cloudwatch/home?region={REGION}#logsV2:log-groups")
    else:
        print("\n Some deployments failed. Check errors above.")
    
    return all_success


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

