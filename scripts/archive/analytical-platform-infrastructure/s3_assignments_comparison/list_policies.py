import boto3

from typing import Dict, List

client = boto3.client('iam')

def get_role_names() -> List[str]:
    """ Retrieve a list of role names by paginating over list_roles() calls """
    roles = []
    role_paginator = client.get_paginator('list_roles')
    for response in role_paginator.paginate():
        response_role_names = [r.get('RoleName') for r in response['Roles']]
        roles.extend(response_role_names)
    return roles

def get_attached_policies_for_roles(role_names: List[str]) -> Dict[str, List[Dict[str, str]]]:
    """ Create a mapping of role names and any policies they have attached to them by 
        paginating over list_attached_role_policies() calls for each role name. 
        Attached policies will include policy name and ARN.
    """
    policy_map = {}
    policy_paginator = client.get_paginator('list_attached_role_policies')
    for name in role_names:
        print(name)
        if name.startswith('alpha_'):
            role_policies = []
            for response in policy_paginator.paginate(RoleName=name):
                print("Role: {0}\n Policy: {1}\n".format(name,response.get('AttachedPolicies')))
                role_policies.extend(response.get('AttachedPolicies'))
            policy_map.update({name: role_policies})
    return policy_map

def get_policies_for_roles(role_names: List[str]) -> Dict[str, List[Dict[str, str]]]:
    """ Create a mapping of role names and any policies they have attached to them by 
        paginating over list_attached_role_policies() calls for each role name. 
        Attached policies will include policy name and ARN.
    """
    policy_map = {}
    policy_paginator = client.get_paginator('list_role_policies')
    for name in role_names:        
        if name.startswith('alpha_user'):
            role_policies = []
            for response in policy_paginator.paginate(RoleName=name):
                role_policies.extend(response.get('PolicyNames'))
                for policy in response.get('PolicyNames'):
                    role_policy = client.get_role_policy(RoleName=name,PolicyName=policy)
                    content = role_policy['PolicyDocument']
                    for statement in content['Statement']:
                        sid = ""
                        if 'Sid' in statement:
                            sid = statement['Sid']
                        if isinstance(statement['Resource'],str):
                            resource = statement['Resource']
                            if resource.startswith('arn:aws:s3:::'):
                                resource = resource[13:]
                            username = name
                            if name.startswith('alpha_user_'):
                                    username = name[11:]
                            if resource!="*" and sid!='list' and policy!="database-access":
                                print(username+","+resource+","+sid+","+policy)
                        else:                            
                            for resource in statement['Resource']:
                                if resource.startswith('arn:aws:s3:::'):
                                    resource = resource[13:]
                                username = name
                                if name.startswith('alpha_user_'):
                                    username = name[11:]
                                if resource!="*" and sid!='list' and policy!="database-access":
                                    print(username+","+resource+","+sid+","+policy)               
            policy_map.update({name: role_policies})
    return policy_map

role_names = get_role_names()
role_policies = get_policies_for_roles(role_names)

