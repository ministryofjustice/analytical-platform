##################################################
# General
##################################################

account_ids = {
  analytical-platform-data-production       = "593291632749"
  analytical-platform-management-production = "042130406152"
  analytical-platform-production            = "312423030077"
}

environment     = "production"
resource_prefix = "alpha"

tags = {
  business-unit          = "Platforms"
  application            = "Analytical Platform"
  component              = "Tools"
  environment            = "production"
  is-production          = "true"
  owner                  = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  infrastructure-support = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  source-code            = "github.com/ministryofjustice/analytical-platform-infrastructure"
}

##################################################
# Route53
##################################################

route53_zone = "analytical-platform.service.justice.gov.uk"

##################################################
# VPC
##################################################

vpc_cidr                              = "10.69.0.0/16"
vpc_private_subnets                   = ["10.69.0.0/20", "10.69.16.0/20", "10.69.32.0/20"]
vpc_public_subnets                    = ["10.69.48.0/20", "10.69.64.0/20", "10.69.80.0/20"]
vpc_database_subnets                  = ["10.69.96.0/28", "10.69.96.16/28", "10.69.96.32/28"]
nat_gateway_bandwidth_alarm_threshold = 90

##################################################
# EFS
##################################################

efs_file_system_performance_mode             = "generalPurpose"
efs_file_system_throughput_mode              = "bursting"
efs_low_credit_burst_balance_alarm_threshold = 50000

##################################################
# RDS
##################################################

rds_instance_class       = "db.t3.micro"
rds_engine               = "postgres"
rds_family               = "postgres13"
rds_engine_version       = "13.10"
rds_allocated_storage    = 5
rds_deletion_protection  = true
rds_multi_az             = true
rds_storage_encrypted    = true
rds_db_name              = "controlpanel"
rds_snapshot_identifier  = "eks-production-control-panelspsg-db-newly-encrypted"
rds_maintenance_window   = "Mon:00:00-Mon:03:00"
rds_backup_window        = "03:00-06:00"
rds_monitoring_interval  = 30
rds_monitoring_role_name = "ControlPanelRDSMonitoringRole_psgdb-encrypted"
rds_paramaters = [
  {
    name  = "rds.force_ssl"
    value = 1
  },
  {
    name  = "log_statement"
    value = "all"
  },
  {
    name  = "log_hostname"
    value = 1
  },
  {
    name  = "log_connections"
    value = 1
  },
  {
    name         = "shared_preload_libraries"
    value        = "pgaudit"
    apply_method = "pending-reboot"
  }
]
rds_timeouts = {
  create = "40m"
  delete = "40m"
  update = "80m"
}

rds_high_cpu_utilisation_alarm_threshold   = 90
rds_low_cpu_credit_balance_alarm_threshold = 100
rds_high_disk_queue_depth_alarm_threshold  = 64
rds_low_free_storage_space_alarm_threshold = 1073741824
rds_low_disk_burst_balance_alarm_threshold = 15
rds_low_freeable_memory_alarm_threshold    = 128000000
rds_high_swap_usage_alarm_threshold        = 256000000

##################################################
# Redis
##################################################

redis_enabled                    = true
redis_instance_type              = "cache.t3.medium"
redis_family                     = "redis5.0"
redis_engine_version             = "5.0.6"
redis_cluster_size               = 3
redis_namespace                  = "control-panel"
redis_at_rest_encryption_enabled = true
redis_automatic_failover_enabled = true
redis_multi_az_enabled           = true
redis_transit_encryption_enabled = true

redis_alarm_cpu_threshold_percent  = 75
redis_alarm_memory_threshold_bytes = 100000

##################################################
# EKS
##################################################
eks_versions = {
  cluster    = "1.24"
  node-group = "1.24"
}
eks_addon_versions = {
  coredns        = "v1.8.7-eksbuild.3"
  ebs-csi-driver = "v1.16.0-eksbuild.1"
  kube-proxy     = "v1.24.7-eksbuild.2"
  vpc-cni        = "v1.12.2-eksbuild.1"
}
eks_node_group_name_prefix = "prod"
eks_node_group_capacities = {
  desired = 3
  max     = 300
  min     = 3
}
eks_role_mappings = [
  {
    "rolearn" : "arn:aws:iam::525294151996:role/restricted-admin",
    "username" : "restricted-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::525294151996:role/github-actions-privileged",
    "username" : "github-actions-infrastructure",
    "groups" : ["system:masters", "system:bootstrappers"]
  },
  {
    "rolearn" : "arn:aws:iam::042130406152:role/restricted-admin",
    "username" : "restricted-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::312423030077:role/restricted-admin",
    "username" : "restricted-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::525294151996:role/GlobalGitHubActionAdmin",
    "username" : "global-github-actions-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::312423030077:role/GlobalGitHubActionAdmin",
    "username" : "global-github-actions-admin",
    "groups" : ["system:masters"]
  },
  {
    "rolearn" : "arn:aws:iam::042130406152:role/GlobalGitHubActionAdmin",
    "username" : "global-github-actions-admin",
    "groups" : ["system:masters"]
  }
]

eks_node_group_ami_type       = "AL2_x86_64"
eks_node_group_disk_size      = 250
eks_node_group_instance_types = ["r5.2xlarge"]

##################################################
# Control Panel
##################################################

control_panel_kubernetes_service_account = "cpanel:cpanel-frontend"
