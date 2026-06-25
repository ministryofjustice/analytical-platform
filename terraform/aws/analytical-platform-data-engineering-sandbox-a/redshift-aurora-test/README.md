# Aurora PostgreSQL Test

This Terraform configuration sets up a VPC and Aurora PostgreSQL database for testing.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                            VPC                                  │
│  ┌──────────────────┐                                           │
│  │ Aurora PostgreSQL│                                           │
│  │    (Port 5432)   │                                           │
│  └──────────────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────┐                                           │
│  │  Secrets Manager │                                           │
│  │  (DB Credentials)│                                           │
│  └──────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

## Components

- **VPC**: Isolated network with public, private, and database subnets
- **Aurora PostgreSQL**: Single-instance cluster with managed master password
- **KMS**: Encryption key for secrets and data at rest
- **VPC Endpoints**: S3, Secrets Manager, and STS endpoints for secure access

## Prerequisites

1. AWS credentials with appropriate permissions
2. Terraform >= 1.5
3. Access to the `analytical-platform-data-engineering-sandbox-a` account

## Usage

### Deploy

```bash
cd terraform/aws/analytical-platform-data-engineering-sandbox-a/redshift-aurora-test
terraform init
terraform plan
terraform apply
```

### Connect to Aurora

After deployment, retrieve the master password from Secrets Manager:

```bash
# Get the secret ARN from Terraform output
terraform output aurora_master_secret_arn

# Retrieve the password
aws secretsmanager get-secret-value --secret-id <secret-arn> --query SecretString --output text | jq -r '.password'
```

Then connect using psql or your preferred PostgreSQL client:

```bash
psql -h <aurora_cluster_endpoint> -U postgres -d testdb
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Name of the project | `redshift-aurora-test` |
| `environment` | Environment name | `sandbox` |
| `vpc_cidr` | CIDR block for the VPC | `10.100.0.0/16` |
| `aurora_instance_class` | Aurora instance class | `db.t3.medium` |
| `aurora_engine_version` | Aurora PostgreSQL version | `16.1` |

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | The ID of the VPC |
| `aurora_cluster_endpoint` | Aurora PostgreSQL endpoint |
| `aurora_cluster_reader_endpoint` | Aurora PostgreSQL reader endpoint |
| `aurora_cluster_port` | Aurora PostgreSQL port |
| `aurora_master_secret_arn` | ARN of the master password secret |

## Cost Considerations

This test environment is configured for minimal cost:
- Aurora uses `db.t3.medium` instance
- Single NAT Gateway
- No deletion protection enabled

**Remember to destroy the infrastructure when not in use:**
```bash
terraform destroy
```

## Security Notes

- All data is encrypted at rest using KMS
- Network traffic stays within the VPC using VPC endpoints
- Master password is stored in AWS Secrets Manager and rotated automatically
