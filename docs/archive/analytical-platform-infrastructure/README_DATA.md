<!-- markdownlint-disable -->
# analytics-platform-data-infrastructure
Infrastructure data resources in the AWS data account

These are the infrastructure definition for the EKS analytical platform. It consists of terraform definitions for resources for the data AWS account.

For using [DBeaver](https://dbeaver.io/) with Redshift see [DBEAVER.md](DBEAVER.md)

For using [Superset](https://superset.apache.org/) with Redshift see [SUPERSET.md](SUPERSET.md)

## data directory

**NOTE:** For terraform to apply successfully the Development Redshift cluster needs to be available. We Pause it when not in use to save money. The Github actions will alert you if the Cluster is not available. To make the Cluster available:
- In the AWS console logon to the data account `593291632749` as restricted admin
- Go to Amazon Redshift service. 
- Select Clusters
- Click on `dev-mi-alpha-ra3`
- Choose action `Resume`

The Development Redshift cluster is paused every evening at 6pm. 


This folder creates resources needed in the AWS Data account

- IAM roles to allow access from various applications to resources in the data account. 

- An AWS Privatelink to the Dev Control Panel database so the the control panel can be developed to allow it to keep the existing alpha control panel db in-sync with new EKS control panel database as part of a migration strategy to EKS. 

- Creates a redshift cluster in the AWS data account dev vpc. 

- Create role to use in AWS console when setting up schedule to pause/resume redshift as currently can't setup 

- Create roles for athena and quicksight to support a separate athena workspace for the mi-alpha project

- Create security group to allow quicksight to access dev vpc storage and private subnets

## scripts directory 

These are various scripts run for various purposes that are not terraform code.  

## Dependencies

- Terraform 0.14+
- [direnv](https://direnv.net/)
- [aws-vault and profiles setup](https://github.com/ministryofjustice/analytical-platform-iam/blob/main/documentation/AWS-CLI.md) to access the relevant accounts

## Usage

### Local Development

After installing [direnv](direnv.net) follow the [aws-vault setup guide](https://github.com/ministryofjustice/analytical-platform-iam/blob/main/documentation/AWS-CLI.md) found in the analytical-platform-iam repository.

This repository uses [Terraform workspaces](https://www.terraform.io/docs/state/workspaces.html#using-workspaces).

If you have direnv installed, it will automatically set the `TF_WORKSPACE` variable, selecting the `development` workspace

You will need credentials from the `landing` account to be able to plan/apply Terraform.

```shell
aws-vault exec landing -- terraform plan
```

### Unlocking State 

if you cancel a github action workflow will need to unlock the state (as we keep a lock in dynamodb table). To unlock data directory in a terminal session in the data directory:
```
export AWS_PROFILE=landing (or use aws-vault to setup landing account access)
export TF_VAR_assume_role=restricted_admin
export TF_WORKSPACE=data

terraform init 
terraform force-unlock 5dc15a03-4ef6-852f-eae3-ef10143a7e26
```
(lock id can be found in the terraform github action run that was cancelled).

### Importing existing resources 

To import existing resources from the current AWS data account 593291632749:

1. In a branch add the new resource to the terraform files. For example: 
``` 
resource "aws_s3_bucket" "mojap-elastic-backup" {
  bucket = "mojap-elastic-backup"
}
```

2. Add in .github/workflow/data.yaml after terraform validate step to import the resource
```
- name: Terraform import
    id: import
    run: terraform import aws_s3_bucket.mojap-elastic-backup mojap-elastic-backup
	working-directory: ${{ env.working-directory }}
```
3. Push branch and create PR. The github action workflow should import the resource and the plan should show no additions. 

4. Then remove the Terraform import step from the workflow, git push and then merge the PR into main branch. 


## References

[https://learn.hashicorp.com/tutorials/terraform/github-actions](https://learn.hashicorp.com/tutorials/terraform/github-actions)

[https://wahlnetwork.com/2020/05/12/continuous-integration-with-github-actions-and-terraform](https://wahlnetwork.com/2020/05/12/continuous-integration-with-github-actions-and-terraform)

