# S3 Assignments Comparison 

## Overview

S3 Assignments are setup in the Control Panel which calls the AWS IAM API to update the s3-access inline policy for the IAM role of the AWS user. 

The Control Panel has a database where it tracks these S3 assignments and this for various reasons gets out of sync with the s3-access policy in AWS. 

## Process

A comparison was undertaken of the data in the Control Panel vs the data in the AWS IAM policy: 
1. Use the DBeaver tool to get the Control Panel S3 Assignment data out to a csv file. 
2. Create a python script `compare_policies.py` to read in the s3assignment data and read the IAM policies and compare them and find:
- IAM Policies with No Bucket Assignment in ControlPanel database
- Buckets Assignments in ControlPanel database with No IAM Policy
3. The output file was uploaded to Google Docs for review and we need to manually edit the IAM policies to be consistent with the Control Panel Database and possibly update the Control Panel database where necessary.  


## Get the Control Panel S3 Assignment data as a csv file

### Install DBeaver on your workstation 

See [https://dbeaver.io/download/](https://dbeaver.io/download/) 

**NOTE**: Other universal SQL database tools can be used.  

### Allow bastion access to the Control Panel Database

In AWS update the AWS data account update the security group `sg-06b7255bb0c7a8eba - prod-controlpanel-db-nlb`
and add inbound rule 
```
PostgreSQL	TCP	5432	192.168.0.46/32 
```

### In DBeaver create a connection

Create a connection with a SSH tunnel through our bastion server. 

Main Tab
```
server host: alpha-control-panel-db.cyfs8aeszqyh.eu-west-1.rds.amazonaws.com
port: 5432 
Database: controlpanel 
Authentication: Database Native 
UserName: controlpanel 
Password: from secret manager 
```

SSH Tab 
```
check SSH Tunnel 
Host/IP: bastion.alpha.mojanalytics.xyz
User Name: ubuntu
Aurhentication: Public Key 
Private Key: /Users/myusername/.ssh/alpha_id_rsa  (from keybase) 
```

### In DBeaver Run SQL Query

Run the following SQL query and download the result to a csv file `s3bucket.csv`.  

```
select 
LOWER(control_panel_api_user.username),
control_panel_api_s3bucket.name, 
control_panel_api_users3bucket.access_level
from control_panel_api_users3bucket
INNER JOIN control_panel_api_s3bucket ON control_panel_api_users3bucket.s3bucket_id = control_panel_api_s3bucket.id
INNER JOIN control_panel_api_user ON control_panel_api_users3bucket.user_id = control_panel_api_user.auth0_id
ORDER BY control_panel_api_user.username ASC;
```

### Remove bastion access to the Control Panel Database

remove the inbound security group rule added earlier. 

## Install python3 

see [Install both Python 2 and 3 on your mac](https://needoneapp.medium.com/install-both-python-2-and-3-on-your-mac-8a18ebcff07)


## Run script to compare 

```
python3 compare_policies.py > s3_assignment_differences.txt
```

Then review s3_assignment_differences.txt for manual correction. 

After correction run again. 

**NOTE** Even after correction there are some non-standard IAM policy setups and some references to S3 tables that don't start with alpha_ in the s3access policy. 

## Reasons for differences

Mostly caused by deleting S3 buckets in the AWS console, or updating the IAM policies manually. Data Engineering currently do manual updates to the policies. Also There is a limit to the size of IAM policies so if the control panel tries to add too many buckets to the policy it will fail.

Now that it is cleaned up. This process can be run again in a number of months time and see if we have more differences. 



