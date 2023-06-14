<!-- markdownlint-disable -->
# Analytical Platform Infrastructure Security

This documents the various security approaches for the infrastructure 

## Bastions

Bastions are used to protect access to private servers. 

### Accessing bastion 

to access private servers in the AWS data account need to go via the bastion hosts: 

- bastion.dev.mojanalytics.xyz for the Dev VPC 
- bastion.alpha.mojanalytics.xyz for the Alpha VPC

To access the bastion via ssh you need an ssh key for the bastion which is securely passed to you and needs to be placed in your .ssh directory. Then you can access the bastion:  
```
ssh -Att ubuntu@bastion.alpha.mojanalytics.xyz
```
and once there ssh into various private servers. 

### SSH tunnelling 

For tools on your workstation to access private servers need to setup SSH tunnelling. For example to access the quicksight test database in the Dev VPC: 
```
ssh -Att -NL 8886:dev-quicksight-test-db.cyfs8aeszqyh.eu-west-1.rds.amazonaws.com:5432 ubuntu@bastion.dev.mojanalytics.xyz -v
```

then whatever database admin tool you use can be configured to access the database: 
```
host: localhost 
port: 8886 
User sa 
Password xxxxxxxxxx
Database qstest 
```

## Secrets 


## OIDC 


## Auth0 


## References 

[https://github.com/ministryofjustice/analytical-platform-aws-security](https://github.com/ministryofjustice/analytical-platform-aws-security)





