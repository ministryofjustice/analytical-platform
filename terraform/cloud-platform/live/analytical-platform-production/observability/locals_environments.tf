locals {
  environment_configurations = {
    analytical-platform-compute-development = {
      #  notification_policy = "analytical-platform-alerts-slack"
      datasource_name = "mojap-compute-development-cloudwatch"
      s3_buckets      = ["mojap-compute-development-mwaa", "mojap-compute-development-velero"]
      enabled_groups = [
        "NAT Gateway",
        "EKS",
        "MWAA",
        "S3"
      ]
    }

    analytical-platform-development = {
      enabled_groups  = ["Control Panel", "EFS", "EKS"]
      aws_region      = "eu-west-1"
      datasource_name = "mojap-development-cloudwatch"
      #  notification_policy = "analytical-platform-alerts-slack"
    }

    # analytical-platform-compute-production = {
    #  notification_policy = "prod-pagerduty"
    # evaluation_interval = "1m"
    #datasource_name     = "mojap-compute-production-cloudwatch"
    #aws_region          = "eu-west-1"

    #s3_buckets    = ["prod-bucket-1", "prod-bucket-2", "prod-bucket-3"]
    #rds_instances = ["prod-db-1", "prod-db-2"]

    #enabled_groups = [
    # "NAT Gateway",
    #"Transit Gateway",
    # "EKS",
    # "EFS",
    # "S3",
    # "MWAA",
    # "Control Panel",
    #]

    #threshold_overrides = {}
    # }
  }
}
