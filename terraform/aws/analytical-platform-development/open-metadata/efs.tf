#tfsec:ignore:aws-efs-enable-at-rest-encryption
module "efs" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/efs/aws"
  version = "1.2.0"

  name          = "open-metadata"
  encrypted     = false
  attach_policy = false

  mount_targets = {
    "private-subnets-0" = {
      subnet_id = module.vpc.public_subnets[0]
    }
    "private-subnets-1" = {
      subnet_id = module.vpc.public_subnets[1]
    }
    "private-subnets-2" = {
      subnet_id = module.vpc.public_subnets[2]
    }
  }

  security_group_vpc_id = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  access_points = {
    airflow_dags = {
      name = "airflow-dags"
      posix_user = {
        gid = 50000
        uid = 50000
      }
      root_directory = {
        path = "/airflow-dags"
        creation_info = {
          owner_gid   = 50000
          owner_uid   = 50000
          permissions = "775"
        }
      }
    }
    airflow_logs = {
      name = "airflow-logs"
      posix_user = {
        gid = 50000
        uid = 50000
      }
      root_directory = {
        path = "/airflow-logs"
        creation_info = {
          owner_gid   = 50000
          owner_uid   = 50000
          permissions = "775"
        }
      }
    }
  }
}
