### Overview
This repository contains Terraform infrastructure code for deploying the Data Engineering Support Assistant on AWS.
It is infra-only:

- Provisions AWS resources (Lambda, API Gateway, DynamoDB, AOSS, etc.)
- Does not contain application/source code

### Repository Responsibilities

- Deploy AWS infrastructure using Terraform
- Reference pre-built Lambda artifacts stored in S3
- Manage IAM, networking, and service integrations

### How It Works

This repo operates alongside the SOurce/Application repo:

**Source Repo**: Builds Lambda code and uploads zip artifacts to S3
**Infra Repo**: Deploys infrastucutre and references those artifacts

### KEY Constraint

AWS Lambda requires code, but this repo must remain code-free.

This is solved using a shared artifact bucket:

    - Lambda zip files are uploaded from the Source repo
    - Terraform references them via S3 keys

### Deployment Flow (High Level)
1) Build and upload Lambda artifacts (Source repo)
2) Run Terraform apply (Infra repo)
3) Manual Knowledge Base setup (required due to SCP restriction)
4) Inject KB_ID and redeploy Lambda

### Nuke / Recovery Model
This environment is regularly reset using aws-nuke.
Only the following resources persist:

    - Terraform state bucket
    - Lock table
    - Lambda artifact bucket

All other resources are recreated via Terraform.

### Quick Start

``
cd terraform/environments/dev

terraform init
terraform validate
terraform apply
``

- Ensure Lambda artifacts already exist in the S3 artifact bucket before running apply

---

### Known Limitation (Important)

An AWS Organisation SCP blocks OpenSearch data-plane access:

Cannot create:

Vector index
Bedrock Knowledge Base
Data source

- These must be created manually after Terraform runs.

---

### Future State
Once SCP restrictions are removed:

    - Terraform will fully automate all resources
    - No manual steps required

---

### CI/CD

Terraform can also be executed via:
.github/workflows/infra.yml

---

### Notes

    - Do not run multiple Terraform applies concurrently
    - Never hardcode dynamic values (e.g. KB_ID, Collection ARN)
    - Always use the shared state backend