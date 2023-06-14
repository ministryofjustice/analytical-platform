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

def get_policies_for_roles(role_names: List[str]) -> Dict[str, List[Dict[str, str]]]:
    buckets = {}
    buckets_found = {}

    from csv import reader
    with open('./s3bucket.csv', 'r') as read_obj:
        csv_reader = reader(read_obj)
        for row in csv_reader:        
            buckets[row[0]+","+row[1]] = row[2]
     
    print('IAM Policies with No Bucket Assignment in ControlPanel database\n')
    policy_paginator = client.get_paginator('list_role_policies')
    for name in role_names:        
        if name.startswith('alpha_user_'):
            username = name[11:]
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
                            if resource.endswith('/*'):
                                size = len(resource)
                                resource = resource[:size - 2]
                            if "/" in resource:
                                resource = resource.split("/")[0]
                                #print(resource)
                            if resource!="*" and sid!='list' and policy!="database-access":
                                found="false"                                
                                sid_value = buckets.get(username+","+resource,"")
                                if sid_value==sid:
                                    found="true"
                                    buckets_found[username+","+resource] = "true"
                                else:  
                                    print(username+","+resource+","+sid+","+policy+","+found)
                            if resource!="*" and sid=='list':
                                found="false"                                
                                sid_value = buckets.get(username+","+resource,"")
                                if sid_value=="readwrite" or sid_value=="readonly":
                                    found="true"
                                    buckets_found[username+","+resource] = "true"
                        else:                            
                            for resource in statement['Resource']:
                                if resource.startswith('arn:aws:s3:::'):
                                    resource = resource[13:]
                                if resource.endswith('/*'):
                                    size = len(resource)
                                    resource = resource[:size - 2]
                                if "/" in resource:
                                    resource = resource.split("/")[0]
                                    #print(resource)
                                if resource!="*" and sid!='list' and policy!="database-access":
                                    found="false"
                                    sid_value = buckets.get(username+","+resource,"")
                                    if sid_value==sid:
                                        found="true"
                                        buckets_found[username+","+resource] = "true"
                                    else: 
                                        print(username+","+resource+","+sid+","+policy+","+found)
                                if resource!="*" and sid=='list':
                                    found="false"                                
                                    sid_value = buckets.get(username+","+resource,"")
                                    if sid_value=="readwrite" or sid_value=="readonly":
                                        found="true"
                                        buckets_found[username+","+resource] = "true"                       
    print('\nBuckets Assignments in ControlPanel database with No IAM Policy\n')
    for bucket in buckets: 
        found = buckets_found.get(bucket)
        if found!="true":
           print(bucket)
    return 

role_names = get_role_names()
role_policies = get_policies_for_roles(role_names)