<!-- markdownlint-disable -->
# Secret Management

## Overview

- We store secrets in [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html).

- We use the [External Secrets controller](https://github.com/external-secrets/kubernetes-external-secrets) to create kubernetes secrets from the secrets held in AWS Secrets Manager.

- We also read some secrets from AWS Secrets Manager and use them as parameters in our terraform configuration.

- We will follow AWS best practice by storing secrets in the same AWS Account that they will be used.

- We will use the Default (AWS Managed) Encryption key to encrypt the secrets in AWS Secrets Manager.

## Naming

We should try to use meaningful names and add a description to secrets that we create in AWS Secrets Manager.

They should be created in the AWS Account that they will be used.

The secret name should be lower case and use the following naming convention

**Environment / Kubernetes namespace or Component name / Secret name**

e.g. for a secret in the **development** EKS cluster, in the **filebeat** namespace that contains credentials to connect to elastic search

**development/filebeat/elastic-credentials**

### Environment names
 
The environment names are as follows

- development
- production
- github-actions-moj


## Access to secrets 

Access to secrets in AWS Secrets manager is limited by IAM policies. At the moment only people who have the restricted-admin role will have access to view, change or delete secrets in that AWS Account.


## Auditing access 

All access to AWS secrets manager is logged to Cloudtrail. This will track, for example, who accessed, changed or deleted secrets.


## Creating a secret in Kubernetes

In order to create a secret in Kubernetes you need to do the following.

- Create the secret in AWS Secrets Manager (in the same AWS Account that it will be used)

- Create an ExternalSecret resource in the [flux repository](https://github.com/moj-analytical-services/analytical-platform-flux) that points at the secret in AWS Secret Manager.

e.g. example YAML for an External Secret resource

**metadata**

`name` - the name of the Kubernetes secret that will be created

`namepace` - the namespace that the Kubernetes secret that will be created in

**spec**

`key` - the name of the secret in AWS Secrets Manager

`name` - the name of the key in the Kubernetes secret.

`property` - the key in the AWS Secrets Manager secret to read the secret value from.


```
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: cpanel
  namespace: cpanel
spec:
  backendType: secretsManager
  data:
    - key: development/control-panel-db-password
      name: postgres-password
      property: password
      
```     



## Rotating secrets

- If you update a secrets in AWS Secrets manager, the External Secrets controller will update the Kubernetes secret automatically (within a few seconds). 

- After that you will usually have to restart the Pod(s) that are using the secrets so that they read the new value.


## Rolling back to a previous version of a secret

By default AWS Secrets Manager will only retain the last 2 versions of a secret. 

It uses staging labels to track version of a secret. 

The current version of a secret is automatically given a staging label of `AWSCURRENT`. 

The previous version of a secret is automatically given a staging label of `AWSPREVIOUS`.

You can also choose to attach staging labels to other versions of a secret and they will also be retained.


### Listing the versions of a secret 

You can list the versions of a secret using the aws cli.

e.g. to list the current and previous versions

```
aws secretsmanager list-secret-version-ids --secret-id secretname 
```

e.g. to list all versions

```
aws secretsmanager list-secret-version-ids --secret-id secretname --include-deprecated
```

### Changing the current version of a secret

Once you have obtained the version ids of a secret using the commands above, you can rollback to a previous version of a secret.

e.g. 

```
aws secretsmanager update-secret-version-stage --secret-id `secretname` --version-stage AWSCURRENT --move-to-version-id oldversion --remove-from-version-id currentversion
```


## Deleting secrets in AWS Secrets Manager

AWS Secrets Manager intentionally makes deleting a secret difficult. 

AWS Secrets Manager does not immediately delete secrets. Instead, it immediately makes the secrets inaccessible and scheduled for deletion after a recovery window of a minimum of seven days. 

Until the recovery window ends, you can recover a secret you previously deleted.

## Potential future enhancements

### Region replication
It is possible to replicate secrets to another AWS region. As we currently only have resources for all other AWS resource in one region, this probably does not provide much benefit for us at the moment.

### Tagging
You can add tags to secrets and then use these tags in IAM policies, so you can dictate which users/roles can view each secret. At the moment we will allow anyone who has access to AWS Secrets Manager to view all of the secrets in that AWS Account.

### Automatic rotation

It is possible to configure AWS Secrets Manager to automatically rotate secrets. As we are primarily using AWS Secrets Manager to provision secrets in Kubernetes, which generally need us to restart Pods after a secret is updated, then we will not use Automatic rotation at the moment.



## References

[https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)

[https://github.com/external-secrets/kubernetes-external-secrets](https://github.com/external-secrets/kubernetes-external-secrets)