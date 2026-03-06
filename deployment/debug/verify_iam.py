"""
Check if Lambda has required Bedrock permissions (InvokeModel, Retrieve).
Run when Lambda fails with AccessDenied errors.
"""
import boto3
import json
from config import FUNCTION_NAME, REGION

def verify_lambda_permissions():
    """Check what permissions Lambda actually has"""
    print("\n Verifying Lambda IAM Permissions")
    print("="*60)
    
    iam = boto3.client('iam')
    lambda_client = boto3.client('lambda', region_name=REGION)
    
    try:
        response = lambda_client.get_function(FunctionName=FUNCTION_NAME)
        role_arn = response['Configuration']['Role']
        role_name = role_arn.split('/')[-1]
        
        print(f"\n Lambda Function: {FUNCTION_NAME}")
        print(f" IAM Role: {role_name}")
        print(f" Role ARN: {role_arn}")
        
        print(f"\n Inline Policies:")
        inline_policies = iam.list_role_policies(RoleName=role_name)
        
        if not inline_policies['PolicyNames']:
            print("No inline policies found!")
        else:
            for policy_name in inline_policies['PolicyNames']:
                print(f"   ✓ {policy_name}")
                policy_doc = iam.get_role_policy(RoleName=role_name, PolicyName=policy_name)
                print(f"\n Policy Document ({policy_name}):")
                print(json.dumps(policy_doc['PolicyDocument'], indent=4))
        
        print(f"\n Managed Policies:")
        managed_policies = iam.list_attached_role_policies(RoleName=role_name)
        for policy in managed_policies['AttachedPolicies']:
            print(f"   ✓ {policy['PolicyName']}")
        
        print(f"\n Checking for Bedrock Permissions...")
        has_invoke = False
        has_retrieve = False
        
        for policy_name in inline_policies['PolicyNames']:
            policy_doc = iam.get_role_policy(RoleName=role_name, PolicyName=policy_name)
            policy_str = json.dumps(policy_doc['PolicyDocument'])
            
            if 'bedrock:InvokeModel' in policy_str:
                has_invoke = True
                print("   ✓ bedrock:InvokeModel found")
            if 'bedrock:Retrieve' in policy_str:
                has_retrieve = True
                print("   ✓ bedrock:Retrieve found")
        
        if not has_invoke:
            print(" bedrock:InvokeModel NOT FOUND")
        if not has_retrieve:
            print(" bedrock:Retrieve NOT FOUND")
        
        return has_invoke and has_retrieve
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    if verify_lambda_permissions():
        print("\n Permissions look correct!")
    else:
        print("\n Missing Bedrock permissions - run fix_iam.py")

