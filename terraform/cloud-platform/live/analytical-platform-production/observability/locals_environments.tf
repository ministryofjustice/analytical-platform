locals {
  environment_configurations = {
    # ---------------------------------------------------------------------------
    # REFERENCE BLOCK — every supported field with description.
    # analytical-platform-compute-<env> = {
    #
    #   # ── Slack ─────────────────────────────────────────────────────────────
    #   # Default Slack channel for all alerts in this environment.
    #   # Individual signals can override this via their own slack_channel field.
    #   # Omit entirely to let Grafana's root policy handle routing.
    #   slack_channel = "dev-slack"
    #
    #   # ── CloudWatch ────────────────────────────────────────────────────────
    #   # Grafana datasource name for CloudWatch (used by all non-Prometheus rules).
    #   # Must exactly match the datasource name configured in Grafana.
    #   cloudwatch_datasource_name = "mojap-compute-<env>-cloudwatch"
    #
    #   # AWS region for CloudWatch API calls.
    #   # Omit to fall back to the module-level var.aws_region default.
    #   aws_region = "eu-west-1"
    #
    #   # ── Prometheus ────────────────────────────────────────────────────────
    #   # Grafana datasource name (or UID) for Prometheus.
    #   # Required only when any signal uses datasource_type = "prometheus".
    #   prometheus_datasource_name = "mojap-compute-<env>-prometheus"
    #
    #   # ── Alert groups ──────────────────────────────────────────────────────
    #   # Which signal groups to enable for this environment.
    #   # Must match keys defined in local.group_folders in local_signals.tf:
    #   #   "NAT Gateway"     → internal/compute/networking
    #   #   "Transit Gateway" → internal/compute/networking
    #   #   "Network Monitor" → internal/compute/networking
    #   #   "EKS"             → internal/compute/cluster
    #   #   "EFS"             → internal/compute/storage
    #   #   "S3"              → internal/compute/storage
    #   #   "MWAA"            → internal/compute/airflow
    #   #   "Control Panel"   → internal/compute/cluster
    #   #                        ↳ REQUIRES: namespaces, rds_instances, cache_clusters
    #   enabled_groups = [
    #     "NAT Gateway",
    #     "Transit Gateway",
    #     "Network Monitor",
    #     "EKS",
    #     "EFS",             # ← see dependencies below
    #     "S3",
    #     "MWAA",
    #     "Control Panel",   # ← see dependencies below
    #   ]
    #   # ── Disabled rules ────────────────────────────────────────────────────
    #   # List of individual signal keys to completely exclude from rule creation
    #   # for this environment. The rule will not be created at all (unlike
    #   # slack_channel_overrides = "disabled" which only suppresses Slack routing).
    #   # Keys must exactly match entries in local.golden_signals in local_signals.tf.
    #   # Omit this field (or leave empty) to create all rules in the enabled groups.
    #   disabled_rules = [
    #     "cp_crashloop_backoff",   # ← silences a noisy dev-only alert entirely
    #     "rds_cpu",
    #   ]
    #   # ── EFS dependencies ──────────────────────────────────────────────────
    #   # Required when "EFS" is in enabled_groups and any efs_* signal uses
    #   # dim_key = "FileSystemId" (e.g. efs_throughput).
    #   # One alert rule is generated per file system ID.
    #   efs_file_systems = ["fs-abc1234567890", "fs-def0987654321"]
    #
    #   # ── Control Panel dependencies ─────────────────────────────────────────
    #   # Required when "Control Panel" is in enabled_groups.
    #   # All three must be provided — missing any will silently drop those rules.
    #
    #   namespaces = ["cpanel"]
    #
    #   # RDS instance identifiers for all rds_* signals (dim_key = "DBInstanceIdentifier").
    #   rds_instances = ["eks-<env>-control-panel-db"]
    #
    #   # ElastiCache base cluster names for all redis_* signals (dim_key = "CacheClusterId").
    #   cache_clusters = ["dev-0001-001"]
    #
    #   # ── S3 ────────────────────────────────────────────────────────────────
    #   # Required when "S3" is in enabled_groups.
    #   s3_buckets = ["mojap-compute-<env>-mwaa", "mojap-compute-<env>-velero"]
    #
    #   # ── Alert evaluation ───────────────────────────────────────────────────
    #   # How often Grafana evaluates the alert rules in this environment.
    #   # Omit to use the module-level var.evaluation_interval default.
    #   evaluation_interval = "1m"
    #
    #   # ── Threshold overrides ────────────────────────────────────────────────
    #   # Per-environment overrides for any threshold key defined in local.defaults
    #   threshold_overrides = {
    #     cp_pod_net_baseline_warn = 5
    #   }
    #   # ── Slack channel overrides ───────────────────────────────────────────
    #   # Per-signal Slack overrides for this environment.
    #   # Use "disabled" to suppress Slack routing for a specific signal
    #   # without affecting other environments (e.g. silence noisy dev alerts).
    #   slack_channel_overrides = {
    #     cp_crashloop_backoff = { warning = "disabled", critical = "disabled" }
    #   }
    # }
    # ---------------------------------------------------------------------------


    analytical-platform-compute-development = {
      #slack_channel = "analytical-platform-alerts-slack"
      cloudwatch_datasource_name = "mojap-compute-development-cloudwatch"
      prometheus_datasource_name = "mojap-compute-development-prometheus"

      # S3 dependencies
      s3_buckets = ["mojap-compute-development-mwaa", "mojap-compute-development-velero"]
      enabled_groups = [
        "NAT Gateway",
        "Transit Gateway",
        "EKS",
        "MWAA",
        "S3"
      ]
    }

    analytical-platform-compute-test = {
      #slack_channel = "analytical-platform-alerts-slack"
      cloudwatch_datasource_name = "mojap-compute-test-cloudwatch"
      prometheus_datasource_name = "mojap-compute-test-prometheus"

      # S3 dependencies
      s3_buckets = ["mojap-compute-test-mwaa", "mojap-compute-test-velero"]
      enabled_groups = [
        "NAT Gateway",
        "Transit Gateway",
        "EKS",
        "MWAA",
        "S3",
        "Network Monitor"
      ]
    }

    analytical-platform-compute-production = {
      #slack_channel = "analytical-platform-alerts-slack"
      cloudwatch_datasource_name = "mojap-compute-production-cloudwatch"
      prometheus_datasource_name = "mojap-compute-production-prometheus"

      # S3 dependencies
      s3_buckets = ["mojap-compute-production-mwaa", "mojap-compute-production-velero"]
      enabled_groups = [
        "NAT Gateway",
        "Transit Gateway",
        "EKS",
        "MWAA",
        "S3",
        "Network Monitor"
      ]
    }

    # environnment added for testing controlpanel alerts purposes, to be removed after testing is complete
    analytical-platform-development = {
      enabled_groups             = ["Control Panel", "EFS"]
      aws_region                 = "eu-west-1"
      cloudwatch_datasource_name = "mojap-development-cloudwatch"
      #  slack_channel = "analytical-platform-alerts-slack"

      efs_file_systems = ["fs-0dbd6739"] #eks-development-user-homes

      # no prometheus configured on this environment
      disabled_rules = [
        "cp_crashloop_backoff",
        "cp_image_pull_backoff",
        "cp_deploy_unavailable",
        "cp_deploy_not_progressing",
        "cp_deploy_replicas_mismatch",
        "cp_deploy_pod_cpu_throttle",
        "cp_deploy_pod_memory_limit",
        "cp_deploy_container_restarts",
        "cp_deploy_pvc_usage"
      ]
      # Control Panel dependencies
      namespaces     = ["cpanel"]
      rds_instances  = ["eks-development-control-panel-psg-db-encrypted"]
      cache_clusters = ["development-control-panel-redis-001", "development-control-panel-redis-002", "development-control-panel-redis-003"]
    }
  }
}
