terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "aws/analytical-platform-development/open-metadata/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "2.6.1"
    }
  }
  required_version = "~> 1.5"
}

provider "auth0" {
  domain        = data.aws_secretsmanager_secret_version.auth0_domain.secret_string
  client_id     = data.aws_secretsmanager_secret_version.auth0_client_id.secret_string
  client_secret = data.aws_secretsmanager_secret_version.auth0_client_secret.secret_string
}

provider "aws" {
  alias = "session"
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-management-production"
  region = "eu-west-1"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "kubernetes" {
  host                   = "https://296807A4C0FC1B3F2FD8A51FA26211C6.gr7.eu-west-2.eks.amazonaws.com"
  cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJek1EWXlNREUxTlRjeU1Gb1hEVE16TURZeE56RTFOVGN5TUZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTWM1CjZIb0tpWjFYSXhjQ0pNZGxqWlJlVGdYNkxraUYwMVB6Sy9WVVdtQzF4bVJxckVVZHpjenhsa2RDYWhiUXI2Q2QKa1k2a1d1UkNhYUV1bTNkZ0xkZm52SldOR3BSTWJtY0ZCOEl3U1RFdFZ1WG9pSk9sb2Vld0NOQ05kM3YxR3FJSQpkekw5UVo4WEpBZW5aQ2VPVVZVaGJMY21rRWxhdExqaTRVbGhHM3AxWCt6UU44U3VYckhSREYwWWExZWs3dTRPCnR0ZjFqUjczS0wxZkl2ZEkzQVlYeEY0Wmd2ZlNRRTdRNERUMjQ5N1dleU52LzRLTjNaUzlFY3dSWFNmMHhMU3MKQ0lrWHBuU3Q1bUtNMDJJemNKR0xvVFlYVmZ2cys3aXdPMVVBSm1kbVRBc1pYWDhZQzEyL0tweVR3OWQyei9zYwp1Q050QUpuM3BIaFRENlk5cjRjQ0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZLTitzbjdWZ1Y3NlNqV294SU5OT2JJNFFGVkhNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBSXhienZLcU83QTBDS0MzUkpzLwpzWWU2aC9tMmd1STVVSThiMFFuNTVoSG5tRWdCZkFseUV1TDBVT256M0krZE51eFFLUDc1M3YzME1UYjZUc3lLCnp6M3FMTnozY0x1V1gwSnRhUlVsRHQrb0s4ZXVtQWROSTVBeFR0QkhrSHlrRU0xMXBjYTVhQnlramNpWUNSM3cKVDQ1OFhscEJBVjlzVFA5RFM4c00vblZpV0kxaGhReDVHM1FpQmJwZVJoMjVQWTBPbkJORUt6cENta3RUdDZoUgpUK2VlRFlwRHdNYVE2dWhBYTdjWUJsVkF2WkxTUlZBMER2V1JESkk5L3UyeW1IOHBzUGl0SmdNQjBQVVlvRTVXCmpXd0JxU2R6ZDlUNnZ3c2taR1gxMlpkRm9rWEVuN0dJV1FxLzdsKzVqajJEcTNrUDZnZkJmV2dZNVhsMU45QzUKSlY4PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "bash"
    args        = ["../../../../scripts/eks/terraform-authentication.sh", data.aws_caller_identity.current.account_id, "open-metadata"]
  }
}
