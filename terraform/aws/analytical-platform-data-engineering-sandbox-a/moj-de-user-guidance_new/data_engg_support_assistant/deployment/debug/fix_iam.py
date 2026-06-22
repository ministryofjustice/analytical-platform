"""
Add missing Bedrock permissions to Lambda's IAM role.
Run once if verify_iam shows missing bedrock:InvokeModel or bedrock:Retrieve.
"""
import boto3
import json

def fix_lambda_permissions():
    """Add Bedrock permissions to Lambda role"""
    
    # Get role name from verify_iam.py output
    role_name = input("Enter Lambda role name (from verify_iam.py): ").strip()
    
    iam = boto3.client('iam')
    
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": ["bedrock:InvokeModel"],
                "Resource": "arn:aws:bedrock:eu-west-2::foundation-model/*"
            },
            {
                "Effect": "Allow",
                "Action": ["bedrock:Retrieve"],
                "Resource": "arn:aws:bedrock:eu-west-2:*:knowledge-base/*"
            }
        ]
    }
    
    try:
        iam.put_role_policy(
            RoleName=role_name,
            PolicyName='BedrockAccess',
            PolicyDocument=json.dumps(policy)
        )
        print(" Bedrock permissions added!")
        print("   Run verify_iam.py again to confirm")
    except Exception as e:
        print(f" Error: {e}")

if __name__ == "__main__":
    fix_lambda_permissions()