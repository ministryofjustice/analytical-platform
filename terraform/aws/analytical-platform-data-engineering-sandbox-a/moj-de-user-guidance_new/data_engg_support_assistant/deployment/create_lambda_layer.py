"""
Lambda Layer Builder for SmartRAG Dependencies

Creates and publishes a Lambda layer containing all Python dependencies
from requirements-lambda.txt, keeping the main deployment package small.

Usage:
    python deployment/create_lambda_layer.py

What it does:
    1. Installs dependencies to layer/python/ directory
    2. Creates zip file (auto-uploads via S3 if >50MB)
    3. Publishes to AWS Lambda Layers
    4. Returns layer ARN for use in deploy_lambda.py

Key Features:
    - Auto-detects size and chooses upload method (direct <50MB, S3 >50MB)
    - Compatible with Python 3.11 & 3.12
    - Validates 250MB unzipped size limit
    - Auto-creates S3 bucket if needed

Prerequisites:
    - requirements-lambda.txt exists
    - AWS credentials configured
    - Sufficient disk space (~500MB temporary)

Output:
    Layer ARN: arn:aws:lambda:REGION:ACCOUNT:layer:smart-rag-dependencies:VERSION
"""
# deployment/create_lambda_layer.py
import subprocess
import zipfile
import boto3
import shutil
import sys
import time
from pathlib import Path

# Add parent directory to path to import config
sys.path.insert(0, str(Path(__file__).parent.parent))
from config import REGION, LAYER_NAME

def create_layer():
    """
    Creates Lambda layer with all dependencies from requirements-lambda.txt
    """
    print("="*60)
    print(" CREATING LAMBDA LAYER")
    print("="*60)
    
    project_root = Path(__file__).parent.parent
    layer_dir = Path('layer/python')
    layer_zip = Path('dependencies-layer.zip')
    requirements_file = project_root / 'requirements-lambda.txt'
    
    # ==================== VALIDATE ====================
    print("\n✓ 1. Validating...")
    
    if not requirements_file.exists():
        print(f" {requirements_file} not found!")
        print("   Create it with Lambda-only dependencies")
        return None
    
    print(f"   ✓ Found {requirements_file}")
    
    # ==================== CLEAN ====================
    print("\n✓ 2. Cleaning old builds...")
    
    if layer_dir.parent.exists():
        shutil.rmtree(layer_dir.parent)
        print("   ✓ Removed old layer/ directory")
    
    if layer_zip.exists():
        layer_zip.unlink()
        print("   ✓ Removed old dependencies-layer.zip")
    
    layer_dir.mkdir(parents=True)
    print("   ✓ Created fresh layer/python/ directory")
    
    # ==================== INSTALL DEPENDENCIES ====================
    print("\n✓ 3. Installing dependencies...")
    print("   → This may take 2-3 minutes for large packages...")
    
    try:
        result = subprocess.run([
            sys.executable, '-m', 'pip', 'install',
            '-r', str(requirements_file),
            '-t', str(layer_dir),
            '--upgrade',
            '--platform', 'manylinux2014_x86_64',
            '--only-binary=:all:',
            '--python-version', '3.12',
            '--no-cache-dir'
        ], capture_output=True, text=True, check=True)
        
        print("   ✓ Dependencies installed")
        
        # Show size
        total_size = sum(f.stat().st_size for f in layer_dir.rglob('*') if f.is_file())
        print(f"   ✓ Layer directory size: {total_size / (1024*1024):.1f} MB")
        
    except subprocess.CalledProcessError as e:
        print(f"\n Installation failed!")
        print(f"\nSTDOUT:\n{e.stdout}")
        print(f"\nSTDERR:\n{e.stderr}")
        return None
    
    # ==================== CREATE ZIP ====================
    print("\n✓ 4. Creating layer zip...")
    
    with zipfile.ZipFile(layer_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file_path in layer_dir.rglob('*'):
            if file_path.is_file():
                # Important: maintain 'python/' structure for Lambda
                arcname = file_path.relative_to(layer_dir.parent)
                zipf.write(file_path, arcname)
    
    size_mb = layer_zip.stat().st_size / (1024 * 1024)
    print(f"   ✓ Layer zip size: {size_mb:.1f} MB")
    
    if size_mb > 250:
        print(f"    Layer exceeds 250 MB unzipped limit!")
        print("   → Remove unnecessary packages from requirements-lambda.txt")
        return None
    
    # ==================== PUBLISH TO AWS ====================
    print("\n✓ 5. Publishing layer to AWS...")
    
    # Choose upload method based on size
    if size_mb > 50:
        print(f"   → Layer > 50MB, uploading via S3...")
        layer_arn = _publish_layer_via_s3(layer_zip, size_mb)
    else:
        print(f"   → Layer < 50MB, uploading directly...")
        layer_arn = _publish_layer_direct(layer_zip, size_mb)
    
    if not layer_arn:
        return None
    
    # Get layer version
    lambda_client = boto3.client('lambda', region_name=REGION)
    layer_version = layer_arn.split(':')[-1]
    
    # ==================== CLEANUP ====================
    print("\n✓ 6. Cleaning up temporary files...")
    
    try:
        if layer_dir.parent.exists():
            shutil.rmtree(layer_dir.parent)
        if layer_zip.exists():
            layer_zip.unlink()
        print("   ✓ Cleanup complete")
    except Exception as e:
        print(f"   ⚠️  Cleanup warning: {e}")
    
    # ==================== SUCCESS ====================
    print("\n" + "="*60)
    print(" LAYER CREATED SUCCESSFULLY!")
    print("="*60)
    print(f"\n Layer Details:")
    print(f"   Name: smart-rag-dependencies")
    print(f"   ARN: {layer_arn}")
    print(f"   Version: {layer_version}")
    print(f"   Size: {size_mb:.1f} MB")
    print(f"   Runtime: Python 3.12")
    
    print("\n Next Steps:")
    print(f"   1. Layer ARN: {layer_arn}")
    print(f"   2. Run: python deployment/deploy_lambda.py")
    print(f"   3. Lambda will auto-detect this layer")
    
    return layer_arn


def _publish_layer_via_s3(layer_zip: Path, size_mb: float) -> str:
    """
    Upload large layer (>50MB) via S3.
    
    Args:
        layer_zip: Path to layer zip file
        size_mb: Size in MB
    
    Returns:
        str: Layer ARN or None if failed
    """
    try:
        s3_client = boto3.client('s3', region_name=REGION)
        lambda_client = boto3.client('lambda', region_name=REGION)
        sts_client = boto3.client('sts')
        
        # Get account ID
        account_id = sts_client.get_caller_identity()['Account']
        bucket_name = f"lambda-layers-{account_id}-{REGION}"
        
        # Create bucket if doesn't exist
        try:
            s3_client.head_bucket(Bucket=bucket_name)
            print(f"   ✓ Using existing bucket: {bucket_name}")
        except:
            print(f"   → Creating S3 bucket: {bucket_name}")
            if REGION == 'us-east-1':
                s3_client.create_bucket(Bucket=bucket_name)
            else:
                s3_client.create_bucket(
                    Bucket=bucket_name,
                    CreateBucketConfiguration={'LocationConstraint': REGION}
                )
            print(f"   ✓ Bucket created")
        
        # Upload to S3
        s3_key = f"layers/smart-rag-dependencies-{int(time.time())}.zip"
        print(f"   → Uploading {size_mb:.1f} MB to S3...")
        
        s3_client.upload_file(
            str(layer_zip),
            bucket_name,
            s3_key,
            ExtraArgs={'ServerSideEncryption': 'AES256'}
        )
        print(f"   ✓ Uploaded to s3://{bucket_name}/{s3_key}")
        
        # Publish layer from S3
        print(f"   → Publishing layer from S3...")
        response = lambda_client.publish_layer_version(
            LayerName=LAYER_NAME,
            Description=f'Dependencies for smart RAG chatbot ({size_mb:.1f} MB)',
            Content={
                'S3Bucket': bucket_name,
                'S3Key': s3_key
            },
            CompatibleRuntimes=['python3.12', 'python3.11'],
            CompatibleArchitectures=['x86_64']
        )
        
        layer_arn = response['LayerVersionArn']
        layer_version = response['Version']
        print(f"   ✓ Layer published: version {layer_version}")
        
        # Optional: Delete S3 file after successful publish
        # Uncomment if you want to save S3 storage costs
        # print(f"   → Cleaning up S3...")
        # s3_client.delete_object(Bucket=bucket_name, Key=s3_key)
        # print(f"   ✓ S3 file deleted")
        
        return layer_arn
        
    except Exception as e:
        print(f" S3 upload failed: {e}")
        import traceback
        traceback.print_exc()
        return None


def _publish_layer_direct(layer_zip: Path, size_mb: float) -> str:
    """
    Upload small layer (<50MB) directly to Lambda.
    
    Args:
        layer_zip: Path to layer zip file
        size_mb: Size in MB
    
    Returns:
        str: Layer ARN or None if failed
    """
    try:
        lambda_client = boto3.client('lambda', region_name=REGION)
        
        with open(layer_zip, 'rb') as f:
            response = lambda_client.publish_layer_version(
                LayerName=LAYER_NAME,
                Description=f'Dependencies for smart RAG chatbot ({size_mb:.1f} MB)',
                Content={'ZipFile': f.read()},
                CompatibleRuntimes=['python3.12', 'python3.11'],
                CompatibleArchitectures=['x86_64']
            )
        
        layer_arn = response['LayerVersionArn']
        layer_version = response['Version']
        print(f"   ✓ Layer published: version {layer_version}")
        
        return layer_arn
        
    except Exception as e:
        print(f" Direct upload failed: {e}")
        import traceback
        traceback.print_exc()
        return None


if __name__ == '__main__':
    create_layer()

""" 
## Key Features
✅ **Auto-detects size** - Uses S3 if > 50MB, direct if < 50MB  
✅ **Creates S3 bucket** - Auto-creates if doesn't exist  
✅ **Cleanup** - Removes temp files  
✅ **Error handling** - Clear error messages  
✅ **Compatible runtimes** - Python 3.11 & 3.12  

"""




