environment                 = "sandbox"
vpc_cidr                    = "172.27.0.0/16"
replication_subnet_group_id = "eu-west-1-sandbox"
import_ids = {
  "vpc"                    = "vpc-0b2907e67278ff255"
  "default_security_group" = "sg-094e03ec1afbae73f"
  "private_network_acl"    = "acl-09e92b531d072d3b9"
  "default_route_table"    = "rtb-0ff5138f54dfff868"
  "vpc_endpoint_security_group" = {
    "name"            = "eu-west-1-sandbox-d7436cd"
    "id"              = "sg-064a3e852f4b852ce"
    "ingress_rule_id" = "sgr-0ad2447598666b8d0"
    "egress_rule_id"  = "sgr-03761b80dcb8fbd94"
  }
  "dms_replication_instance_security_group" = {
    "id"              = "sg-0b767b59a7f79c72c"
    "ingress_rule_id" = "sgr-0a0f769c0dea8b7bc"
    "egress_rule_id"  = "sgr-0456352b32299196f"
  }
  "vpc_endpoint" = {
    "s3"          = "vpce-02f6df37bd54d7fd0"
    "ec2messages" = "vpce-0dd2e0fcb3bfe8883"
    "ssm"         = "vpce-032e5d27a6a47cabb"
    "ssmmessages" = "vpce-0c1fcc574ba3b3c52"
  }
  "route_table_private" = {
    "eu-west-1a" = "rtb-00b2514e95916f4c1"
    "eu-west-1b" = "rtb-032f93e0a0c6e1c56"
    "eu-west-1c" = "rtb-07a62c7dfcf9d83cf"
  }
  "private_subnets" = {
    "eu-west-1a" = {
      "subnet" = "subnet-063c9bf0b02171cc5"
      "cidr"   = "172.27.0.0/20"
    }
    "eu-west-1b" = {
      "subnet" = "subnet-00f37258fadd49a44"
      "cidr"   = "172.27.16.0/20"
    }
    "eu-west-1c" = {
      "subnet" = "subnet-01f59f6f6fe77a6d7"
      "cidr"   = "172.27.32.0/20"
    }
  }
}

#vpc_config = {
#  sandbox = {
#    vpc_cidr = "172.27.0.0/16"
#    import_ids = {
#      "vpc"                    = "vpc-0b2907e67278ff255"
#      "default_security_group" = "sg-094e03ec1afbae73f"
#      "private_network_acl"    = "acl-09e92b531d072d3b9"
#      "default_route_table"    = "rtb-0ff5138f54dfff868"
#      "vpc_endpoint_security_group" = {
#        "name"            = "eu-west-1-sandbox-d7436cd"
#        "id"              = "sg-064a3e852f4b852ce"
#        "ingress_rule_id" = "sgr-0ad2447598666b8d0"
#        "egress_rule_id"  = "sgr-03761b80dcb8fbd94"
#      }
#      "dms_replication_instance_security_group" = {
#        "id"              = "sg-0b767b59a7f79c72c"
#        "ingress_rule_id" = "sgr-0a0f769c0dea8b7bc"
#        "egress_rule_id"  = "sgr-0456352b32299196f"
#      }
#      "vpc_endpoint" = {
#        "s3"          = "vpce-02f6df37bd54d7fd0"
#        "ec2messages" = "vpce-0dd2e0fcb3bfe8883"
#        "ssm"         = "vpce-032e5d27a6a47cabb"
#        "ssmmessages" = "vpce-0c1fcc574ba3b3c52"
#      }
#      "route_table_private" = {
#        "eu-west-1a" = "rtb-00b2514e95916f4c1"
#        "eu-west-1b" = "rtb-032f93e0a0c6e1c56"
#        "eu-west-1c" = "rtb-07a62c7dfcf9d83cf"
#      }
#      "private_subnets" = {
#        "eu-west-1a" = {
#          "subnet" = "subnet-063c9bf0b02171cc5"
#          "cidr"   = "172.27.0.0/20"
#        }
#        "eu-west-1b" = {
#          "subnet" = "subnet-00f37258fadd49a44"
#          "cidr"   = "172.27.16.0/20"
#        }
#        "eu-west-1c" = {
#          "subnet" = "subnet-01f59f6f6fe77a6d7"
#          "cidr"   = "172.27.32.0/20"
#        }
#      }
#    }
#  }
#}

dms_config = {
  oracle19 = {
    envrioment                 = "sandbox"
    source_secrets_manager_arn = "arn:aws:kms:eu-west-1:684969100054:key/a526d2a0-59e6-457f-89eb-524790ea3a30"
    landing_bucket             = "mojap-land-sandbox"
    landing_bucket_folder      = "hmpps/oracle19"
    metadata_bucket            = "mojap-metadata-sandbox"
    fail_bucket                = "mojap-fail-sandbox"
    raw_hist_bucket            = "mojap-raw-hist-sandbox"
    slack_secret_arn           = "arn:aws:secretsmanager:eu-west-1:684969100054:secret:managed_pipelines/sandbox/slack_notifications*"
    role_name                  = "oracle19-dms-sandbox"
    full_load_task_id          = "oracle19-1-1-full-load-eu-west-1-sandbox"
    cdc_task_id                = "oracle19-1-0-cdc-eu-west-1-sandbox"
    replication_instance = {
      replication_instance_id   = "oracle19-1-eu-west-1-sandbox"
      security_group_id         = "sg-0b767b59a7f79c72c"
      security_group_ingress_id = "sgr-0a0f769c0dea8b7bc"
      security_group_egress_id  = "sgr-0456352b32299196f"
    }
  }
}
