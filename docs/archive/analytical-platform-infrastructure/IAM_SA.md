<!-- markdownlint-disable -->
# IAM for Service Accounts

We use IAM for Service Accounts to provide AWS permissions to applications running in EKS.


We do this by creating IAM roles that have a Trust policy that trusts the OIDC provider and one or more Kubernetes service accounts and then adding an annotation to the Kubernetes service account(s) with the name of the Amazon Resource Name (ARN) of the IAM role they should assume.

See the [IAM for Service accounts documentation] (https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) for more details.


## Assuming a role in a different AWS account

The Analytical Tool and Control Panel pods all need to assume an IAM role in a different AWS account to the one that they run in.

i.e. for the Prod EKS environment, the pods runs in the Production AWS account but they need to assume an IAM role in the Data AWS account.

In order to be able to do this we need to create an IAM OIDC provider in the AWS account that we want to be able to assume roles in.

i.e. for the Prod EKS environment this would be the Data AWS account.

We create the IAM OIDC provider using terraform in the [https://github.com/ministryofjustice/analytics-platform-infrastructure](https://github.com/ministryofjustice/analytics-platform-infrastructure) repo.

We have to specify the following details

- `Provider URL` - This should be set to the value of the OpenID Connect provider URL on the EKS cluster where your workloads are running. 

You can find the value of this for a EKS Cluster under Configuration - Details - OpenID Connect provider URL.


- `Audience` - This needs to be set to `sts.amazonaws.com`


You can then create IAM roles that have a Trust policy that trusts this OIDC provider and one or more Kubernetes service accounts and add annotations to the Kubernetes service account(s) with the name of the Amazon Resource Name (ARN) of the IAM role they should assume.

[See these docs for more details ](https://aws.amazon.com/blogs/containers/cross-account-iam-roles-for-kubernetes-service-accounts/)

## Environment variables that are set.

A mutating admission controller that runs in EKS automatically injects the environment variables `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` as well as the `aws-iam-token` volume into pods that are using a Kubernetes service account with the `eks.amazonaws.com/role-arn` annotation.

Applications can use then use the `sts:AssumeRoleWithWebIdentity` call to assume the IAM role.

See the following for more details.

[https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)

[https://medium.com/@toja/eks-iam-roles-for-service-accounts-dfe4fb3b269a](https://medium.com/@toja/eks-iam-roles-for-service-accounts-dfe4fb3b269a)

## RStudio

The RStudio container is set to run as the `root` user but then starts the rstudio process as the `rstudio` user.

The mutating admission controller only sets the `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` environment variables for the user that the container starts as i.e `root`. Therefore these environment variables are not set for the `rstudio` user.

In order to set these for the `rstudio` user we have to use a `.Renviron `file.

See the [RStudio helm chart](https://github.com/ministryofjustice/analytics-platform-helm-charts/tree/main/charts/rstudio) and the following article [https://support.rstudio.com/hc/en-us/articles/360047157094-Managing-R-with-Rprofile-Renviron-Rprofile-site-Renviron-site-rsession-conf-and-repos-conf](https://support.rstudio.com/hc/en-us/articles/360047157094-Managing-R-with-Rprofile-Renviron-Rprofile-site-Renviron-site-rsession-conf-and-repos-conf) for more details.