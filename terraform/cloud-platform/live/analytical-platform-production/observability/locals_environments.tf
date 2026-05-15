locals {
  environment_configurations = {
    analytical-platform-compute-development = {
      #slack_channel = "analytical-platform-alerts-slack"
      cloudwatch_datasource_name = "mojap-compute-development-cloudwatch"
      prometheus_datasource_name = "mojap-compute-development-prometheus"
      s3_buckets                 = ["mojap-compute-development-mwaa", "mojap-compute-development-velero"]
      enabled_groups = [
        "NAT Gateway",
        "EKS",
        "MWAA",
        "S3"
      ]
    }

    analytical-platform-development = {
      enabled_groups             = ["Control Panel", "EFS", "EKS"]
      aws_region                 = "eu-west-1"
      cloudwatch_datasource_name = "mojap-development-cloudwatch"
      prometheus_datasource_name = "mojap-development-prometheus"
      #  slack_channel = "analytical-platform-alerts-slack"
    }

    # analytical-platform-compute-production = {
    # slack_channel = "prod-pagerduty"
    # evaluation_interval = "1m"
    # cloudwatch_datasource_name     = "mojap-compute-production-cloudwatch"
    # prometheus_datasource_name = "mojap-compute-production-prometheus"
    # aws_region          = "eu-west-1"

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
