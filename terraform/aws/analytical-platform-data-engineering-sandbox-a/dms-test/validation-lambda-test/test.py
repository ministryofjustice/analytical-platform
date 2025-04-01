import os
import json
import boto3
import io
import zipfile
from moto import mock_aws  # Alternatively, you can import @mock_s3, @mock_lambda, and @mock_iam individually

# Directory containing your Lambda code (main.py and requirements.txt)
LAMBDA_CODE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../validation-lambda"))

def create_lambda_zip(code_dir, filename="main.py"):
    """
    Create an in-memory ZIP file containing the Lambda function code.
    Only the specified filename is added to the ZIP.
    """
    zip_buffer = io.BytesIO()
    zip_path = os.path.join(code_dir, filename)

    if not os.path.exists(zip_path):
        raise FileNotFoundError(f"{zip_path} does not exist. Please check your Lambda code directory.")

    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        # arcname makes sure the file appears at the root of the ZIP file.
        zf.write(zip_path, arcname=filename)

    zip_buffer.seek(0)
    return zip_buffer.read()

@mock_aws
def test_lambda():
    # -------------------------------
    # Step 1: Create the IAM Role
    # -------------------------------
    iam_client = boto3.client("iam", region_name="us-east-1")
    # Define the trust relationship policy that allows Lambda to assume this role
    assume_role_policy_document = json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "lambda.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    })

    # Create the role for the Lambda function
    role_response = iam_client.create_role(
        RoleName="my-lambda-role",
        AssumeRolePolicyDocument=assume_role_policy_document,
        Description="Role for my lambda function"
    )
    role_arn = role_response["Role"]["Arn"]
    print("IAM Role Created:")

    # -------------------------------
    # Step 2: Set Up S3 and Create a Bucket
    # -------------------------------
    s3_client = boto3.client("s3", region_name="us-east-1")
    bucket_name = "source-bucket"
    s3_client.create_bucket(Bucket=bucket_name)

    # List and print all buckets to verify bucket creation
    buckets_response = s3_client.list_buckets()
    print("Buckets:")

    # -------------------------------
    # Step 3: Prepare the Lambda Function Code
    # -------------------------------
    try:
        zipped_code = create_lambda_zip(LAMBDA_CODE_DIR, filename="main.py")
    except FileNotFoundError as e:
        print(e)
        return

    # -------------------------------
    # Step 4: Create the Lambda Function
    # -------------------------------
    lambda_client = boto3.client("lambda", region_name="us-east-1")

    try:
        lambda_response = lambda_client.create_function(
            FunctionName="my_lambda_function",
            Runtime="python3.11",
            Role=role_arn,  # Use the ARN of the role we just created
            Handler="main.handler",  # Assumes 'handler' function inside main.py
            Code={"ZipFile": zipped_code},
            Description="Validation function for DMS output",
            Timeout=30,
            MemorySize=128,
            Publish=True,
        )
    except Exception as e:
        print("Error creating Lambda function:", e)
        return

    print("Lambda Function Created:")
    #print(json.dumps(lambda_response, default=str, indent=2))

    # -------------------------------
    # Step 5: Invoke the Lambda Function
    # -------------------------------
    try:
        print("Invoking Lambda function...")
        invoke_response = lambda_client.invoke(
            FunctionName="my_lambda_function",
            InvocationType="RequestResponse",
            Payload=json.dumps({})  # Pass an empty JSON payload; modify as needed
        )
        print("Lambda Invocation Result:")
        # Read and decode the response payload
        response_payload = invoke_response["Payload"].read().decode("utf-8")
        print("Lambda Invocation Response:")
        print(response_payload)
    except Exception as e:
        print("Error invoking Lambda function:", e)

if __name__ == "__main__":
    test_lambda()
