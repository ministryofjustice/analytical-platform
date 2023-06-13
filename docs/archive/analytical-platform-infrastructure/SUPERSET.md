<!-- markdownlint-disable -->
# Using Superset with Redshift

## Overview 

Superset is install in the AWS development account in the Development EKS cluster in an experimental fashion.

**NOTE:** It would need work to make it production ready. Tasks like added auth0 2FA authentication. Moving Postgres and REdis to AWS services instead of containers inside EKS. 

## Usage

Superset is accessible via [https://superset.services.dev.analytical-platform.service.justice.gov.uk/](https://superset.services.dev.analytical-platform.service.justice.gov.uk/). 

You need a user and password created. 


## Steps for using Superset with dev_mi_alpha redshift. 

Add database of type redshift with following values 
```
Host: vpce-0ce35b9eac96fc19e-dzimi0gi.vpce-svc-017de894c57756a09.eu-west-1.vpce.amazonaws.com
port: 5439
database name: dev_mi_alpha
username: master
password: from secret manager 
Set ssl on. 
```
