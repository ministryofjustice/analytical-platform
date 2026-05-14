locals {
  # ---------------------------------------------------------------------------
  # group_folders — maps each alert group to its Grafana folder path and
  # the suffix used when naming the rule group in the YAML output.
  # ---------------------------------------------------------------------------
  group_folders = {
    "NAT Gateway"     = { folder = "internal/compute/networking", name_suffix = "natgateway" }
    "Transit Gateway" = { folder = "internal/compute/networking", name_suffix = "transitgateway" }
    "EKS"             = { folder = "internal/compute/cluster", name_suffix = "eks" }
    "EFS"             = { folder = "internal/compute/storage", name_suffix = "efs" }
    "S3"              = { folder = "internal/compute/storage", name_suffix = "s3" }
    "MWAA"            = { folder = "internal/compute/airflow", name_suffix = "mwaa" }
    "Control Panel"   = { folder = "internal/compute/cluster", name_suffix = "cpanel" }
  }

  # ---------------------------------------------------------------------------
  # golden_signals — one entry per CloudWatch metric to alert on.
  #
  # Fields:
  #   group          = alert group name (must match a key in group_folders above)
  #   namespace      = CloudWatch namespace
  #   metric         = CloudWatch metric name
  #   statistic      = CloudWatch statistic (Sum, Average, Maximum, Minimum, p99 …)
  #   type           = alert logic:
  #                      gt          → fire when value > threshold         (condition C)
  #                      lt          → fire when value < threshold         (condition C)
  #                      baseline_gt → fire when % above hourly baseline   (condition D)
  #                      baseline_lt → fire when % below hourly baseline   (condition D)
  #   dim_key        = primary CloudWatch dimension key ("" = no dimension filter)
  #   dim_key2       = optional second dimension key; always matched with value "*"
  #                    used for ContainerInsights metrics that need e.g.
  #                    {Namespace=cpanel, ClusterName=*} to return the
  #                    namespace-level aggregate instead of per-pod series
  #   match_exact    = (optional, default: false)
  #                    if true, CloudWatch returns only series whose dimension set
  #                    exactly matches the supplied keys (no extra dimensions).
  #                    Required for ContainerInsights cluster-level aggregates to
  #                    exclude per-pod series that carry extra dimensions (PodName etc)
  #   ok_when_nodata = (optional, default: false)
  #                    if true, sets noDataState: OK so rules resolve to Normal
  #                    when CloudWatch emits nothing (e.g. zero failed nodes)
  #   slack_channel  = (optional) Slack channel to route this signal's alerts.
  #                    Two forms accepted:
  #                      a) string — same channel for both severities
  #                         slack_channel = "dev-slack"
  #                      b) object — different channel per severity;
  #                         omit a key to emit no label for that severity
  #                         slack_channel = { warning = "dev-slack", critical = "dev-slack-critical" }
  #                    Resolution order per severity (first non-null wins):
  #                      1. per-severity key on this field  (e.g. .critical)
  #                      2. string value on this field
  #                      3. slack_channel in environment_configurations  (env default)
  #                    If none of the above is set the label is omitted entirely
  #                    and Grafana's root / catch-all policy handles the alert.
  #   warning        = key in locals.defaults (or threshold_overrides) for warning level
  #   critical       = key in locals.defaults (or threshold_overrides) for critical level
  # ---------------------------------------------------------------------------
  golden_signals = {

    # ── NAT Gateway ───────────────────────────────────────────────────────────
    natgw_BytesInFromSource          = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "BytesInFromSource", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "natgw_bytes_warn", critical = "natgw_bytes_crit" }
    natgw_BytesOutToDestination      = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "BytesOutToDestination", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "natgw_bytes_warn", critical = "natgw_bytes_crit" }
    natgw_BytesInFromDestination     = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "BytesInFromDestination", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "natgw_bytes_warn", critical = "natgw_bytes_crit" }
    natgw_BytesOutToSource           = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "BytesOutToSource", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "natgw_bytes_warn", critical = "natgw_bytes_crit" }
    natgw_PacketsInFromSource        = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "PacketsInFromSource", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "natgw_packets_warn", critical = "natgw_packets_crit" }
    natgw_PacketsOutToDestination    = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "PacketsOutToDestination", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "natgw_packets_warn", critical = "natgw_packets_crit" }
    natgw_ConnectionAttemptCount     = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "ConnectionAttemptCount", statistic = "Sum", type = "gt", dim_key = "", warning = "natgw_conn_attempt_warn", critical = "natgw_conn_attempt_crit" }
    natgw_ConnectionEstablishedCount = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "ConnectionEstablishedCount", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "natgw_conn_est_baseline_warn", critical = "natgw_conn_est_baseline_crit" }
    natgw_ActiveConnectionCount      = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "ActiveConnectionCount", statistic = "Maximum", type = "gt", dim_key = "", warning = "natgw_active_conn_warn", critical = "natgw_active_conn_crit" }
    natgw_ErrorPortAllocation        = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "ErrorPortAllocation", statistic = "Sum", type = "gt", dim_key = "", warning = "natgw_port_alloc_warn", critical = "natgw_port_alloc_crit" }
    natgw_PacketsDropCount           = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "PacketsDropCount", statistic = "Sum", type = "gt", dim_key = "", warning = "natgw_pkt_drop_warn", critical = "natgw_pkt_drop_crit" }
    natgw_IdleTimeoutCount           = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "IdleTimeoutCount", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "natgw_idle_timeout_baseline_warn", critical = "natgw_idle_timeout_baseline_crit" }
    natgw_PeakBytesPerSecond         = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "PeakBytesPerSecond", statistic = "Maximum", type = "gt", dim_key = "", warning = "natgw_peak_bytes_warn", critical = "natgw_peak_bytes_crit" }
    natgw_PeakPacketsPerSecond       = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "PeakPacketsPerSecond", statistic = "Maximum", type = "gt", dim_key = "", warning = "natgw_peak_pkts_warn", critical = "natgw_peak_pkts_crit" }

    # ── Transit Gateway ───────────────────────────────────────────────────────
    tgw_BytesIn                   = { group = "Transit Gateway", namespace = "AWS/TransitGateway", metric = "BytesIn", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "tgw_traffic_baseline_warn", critical = "tgw_traffic_baseline_crit" }
    tgw_BytesOut                  = { group = "Transit Gateway", namespace = "AWS/TransitGateway", metric = "BytesOut", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "tgw_traffic_baseline_warn", critical = "tgw_traffic_baseline_crit" }
    tgw_PacketsIn                 = { group = "Transit Gateway", namespace = "AWS/TransitGateway", metric = "PacketsIn", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "tgw_traffic_baseline_warn", critical = "tgw_traffic_baseline_crit" }
    tgw_PacketsOut                = { group = "Transit Gateway", namespace = "AWS/TransitGateway", metric = "PacketsOut", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "tgw_traffic_baseline_warn", critical = "tgw_traffic_baseline_crit" }
    tgw_PacketDropCountNoRoute    = { group = "Transit Gateway", namespace = "AWS/TransitGateway", metric = "PacketDropCountNoRoute", statistic = "Sum", type = "gt", dim_key = "", warning = "tgw_pkt_drop_no_route_warn", critical = "tgw_pkt_drop_no_route_crit" }
    tgw_PacketDropCountBlackhole  = { group = "Transit Gateway", namespace = "AWS/TransitGateway", metric = "PacketDropCountBlackhole", statistic = "Sum", type = "gt", dim_key = "", warning = "tgw_pkt_drop_blackhole_warn", critical = "tgw_pkt_drop_blackhole_crit" }
    tgw_PacketDropCountTTLExpired = { group = "Transit Gateway", namespace = "AWS/TransitGateway", metric = "PacketDropCountTTLExpired", statistic = "Sum", type = "gt", dim_key = "", warning = "tgw_pkt_drop_ttl_warn", critical = "tgw_pkt_drop_ttl_crit" }
    tgw_BytesDropCountNoRoute     = { group = "Transit Gateway", namespace = "AWS/TransitGateway", metric = "BytesDropCountNoRoute", statistic = "Sum", type = "gt", dim_key = "", warning = "tgw_bytes_drop_no_route_warn", critical = "tgw_bytes_drop_no_route_crit" }
    tgw_BytesDropCountBlackhole   = { group = "Transit Gateway", namespace = "AWS/TransitGateway", metric = "BytesDropCountBlackhole", statistic = "Sum", type = "gt", dim_key = "", warning = "tgw_bytes_drop_blackhole_warn", critical = "tgw_bytes_drop_blackhole_crit" }

    # ── EKS ───────────────────────────────────────────────────────────────────
    eks_webhook_latency    = { group = "EKS", namespace = "AWS/EKS", metric = "apiserver_admission_webhook_admission_duration_seconds", statistic = "p99", type = "gt", dim_key = "", warning = "eks_webhook_latency_warn", critical = "eks_webhook_latency_crit" }
    eks_node_network       = { group = "EKS", namespace = "ContainerInsights", metric = "node_network_total_bytes", statistic = "Sum", type = "gt", dim_key = "ClusterName", match_exact = true, ok_when_nodata = true, warning = "eks_node_net_warn", critical = "eks_node_net_crit" }
    eks_unhealthy_hosts    = { group = "EKS", namespace = "AWS/NetworkELB", metric = "UnHealthyHostCount", statistic = "Maximum", type = "gt", dim_key = "", warning = "eks_unhealthy_host_warn", critical = "eks_unhealthy_host_crit" }
    eks_tcp_reset          = { group = "EKS", namespace = "AWS/NetworkELB", metric = "TCP_Target_Reset_Count", statistic = "Sum", type = "gt", dim_key = "", warning = "eks_tcp_reset_warn", critical = "eks_tcp_reset_crit" }
    eks_container_restarts = { group = "EKS", namespace = "ContainerInsights", metric = "pod_number_of_container_restarts", statistic = "Sum", type = "gt", dim_key = "ClusterName", match_exact = true, ok_when_nodata = true, warning = "eks_container_restart_warn", critical = "eks_container_restart_crit" }
    eks_failed_nodes       = { group = "EKS", namespace = "ContainerInsights", metric = "cluster_failed_node_count", statistic = "Maximum", type = "gt", dim_key = "ClusterName", match_exact = true, ok_when_nodata = true, warning = "eks_failed_node_warn", critical = "eks_failed_node_crit" }
    eks_pending_pods       = { group = "EKS", namespace = "AWS/EKS", metric = "scheduler_pending_pods_UNSCHEDULABLE", statistic = "Maximum", type = "gt", dim_key = "", ok_when_nodata = true, warning = "eks_pending_pod_warn", critical = "eks_pending_pod_crit" }
    eks_node_cpu           = { group = "EKS", namespace = "ContainerInsights", metric = "node_cpu_utilization", statistic = "Average", type = "gt", dim_key = "ClusterName", match_exact = true, warning = "eks_node_cpu_warn", critical = "eks_node_cpu_crit" }
    eks_node_memory        = { group = "EKS", namespace = "ContainerInsights", metric = "node_memory_utilization", statistic = "Average", type = "gt", dim_key = "ClusterName", match_exact = true, warning = "eks_node_mem_warn", critical = "eks_node_mem_crit" }
    eks_node_disk          = { group = "EKS", namespace = "ContainerInsights", metric = "node_filesystem_utilization", statistic = "Average", type = "gt", dim_key = "ClusterName", match_exact = true, warning = "eks_node_disk_warn", critical = "eks_node_disk_crit" }
    eks_pod_cpu_throttle   = { group = "EKS", namespace = "ContainerInsights", metric = "pod_cpu_utilization_over_pod_limit", statistic = "Average", type = "gt", dim_key = "ClusterName", match_exact = true, warning = "eks_pod_cpu_throttle_warn", critical = "eks_pod_cpu_throttle_crit" }
    eks_pod_memory_limit   = { group = "EKS", namespace = "ContainerInsights", metric = "pod_memory_utilization_over_pod_limit", statistic = "Average", type = "gt", dim_key = "ClusterName", match_exact = true, warning = "eks_pod_mem_limit_warn", critical = "eks_pod_mem_limit_crit" }
    eks_etcd_size          = { group = "EKS", namespace = "AWS/EKS", metric = "apiserver_storage_size_bytes", statistic = "Maximum", type = "gt", dim_key = "", warning = "eks_etcd_size_warn", critical = "eks_etcd_size_crit" }

    # ── EFS ───────────────────────────────────────────────────────────────────
    efs_io_limit           = { group = "EFS", namespace = "AWS/EFS", metric = "PercentIOLimit", statistic = "Average", type = "gt", dim_key = "", warning = "efs_io_limit_warn", critical = "efs_io_limit_crit" }
    efs_metered_io         = { group = "EFS", namespace = "AWS/EFS", metric = "MeteredIOBytes", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "efs_metered_io_baseline_warn", critical = "efs_metered_io_baseline_crit" }
    efs_throughput         = { group = "EFS", namespace = "AWS/EFS", metric = "PermittedThroughput", statistic = "Average", type = "gt", dim_key = "", warning = "efs_throughput_warn", critical = "efs_throughput_crit" }
    efs_client_connections = { group = "EFS", namespace = "AWS/EFS", metric = "ClientConnections", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "efs_client_conn_baseline_warn", critical = "efs_client_conn_baseline_crit" }
    efs_burst_credit       = { group = "EFS", namespace = "AWS/EFS", metric = "BurstCreditBalance", statistic = "Minimum", type = "lt", dim_key = "", warning = "efs_burst_credit_warn", critical = "efs_burst_credit_crit" }

    # ── S3 ────────────────────────────────────────────────────────────────────
    s3_total_latency      = { group = "S3", namespace = "AWS/S3", metric = "TotalRequestLatency", statistic = "p99", type = "gt", dim_key = "BucketName", warning = "s3_latency_total_warn", critical = "s3_latency_total_crit" }
    s3_first_byte_latency = { group = "S3", namespace = "AWS/S3", metric = "FirstByteLatency", statistic = "p99", type = "gt", dim_key = "BucketName", warning = "s3_latency_first_byte_warn", critical = "s3_latency_first_byte_crit" }
    s3_all_requests       = { group = "S3", namespace = "AWS/S3", metric = "AllRequests", statistic = "Sum", type = "baseline_gt", dim_key = "BucketName", warning = "s3_requests_baseline_warn", critical = "s3_requests_baseline_crit" }
    s3_get_requests       = { group = "S3", namespace = "AWS/S3", metric = "GetRequests", statistic = "Sum", type = "baseline_gt", dim_key = "BucketName", warning = "s3_requests_baseline_warn", critical = "s3_requests_baseline_crit" }
    s3_bytes_downloaded   = { group = "S3", namespace = "AWS/S3", metric = "BytesDownloaded", statistic = "Sum", type = "baseline_gt", dim_key = "BucketName", warning = "s3_bytes_dl_baseline_warn", critical = "s3_bytes_dl_baseline_crit" }
    s3_5xx_errors         = { group = "S3", namespace = "AWS/S3", metric = "5xxErrors", statistic = "Average", type = "gt", dim_key = "BucketName", warning = "s3_5xx_warn", critical = "s3_5xx_crit" }
    s3_4xx_errors         = { group = "S3", namespace = "AWS/S3", metric = "4xxErrors", statistic = "Average", type = "gt", dim_key = "BucketName", warning = "s3_4xx_warn", critical = "s3_4xx_crit" }
    s3_bucket_size        = { group = "S3", namespace = "AWS/S3", metric = "BucketSizeBytes", statistic = "Average", type = "gt", dim_key = "BucketName", warning = "s3_bucket_size_warn", critical = "s3_bucket_size_crit" }
    s3_object_count       = { group = "S3", namespace = "AWS/S3", metric = "NumberOfObjects", statistic = "Average", type = "gt", dim_key = "BucketName", warning = "s3_object_count_warn", critical = "s3_object_count_crit" }

    # ── MWAA ──────────────────────────────────────────────────────────────────
    mwaa_parse_time           = { group = "MWAA", namespace = "AmazonMWAA", metric = "TotalParseTime", statistic = "Maximum", type = "gt", dim_key = "", warning = "mwaa_parse_time_warn", critical = "mwaa_parse_time_crit" }
    mwaa_dag_processing_age   = { group = "MWAA", namespace = "AmazonMWAA", metric = "DAGFileProcessingLastRunSecondsAgo", statistic = "Maximum", type = "gt", dim_key = "", warning = "mwaa_dag_processing_age_warn", critical = "mwaa_dag_processing_age_crit" }
    mwaa_task_duration        = { group = "MWAA", namespace = "AmazonMWAA", metric = "TaskInstanceDuration", statistic = "Average", type = "baseline_gt", dim_key = "", warning = "mwaa_task_duration_baseline_warn", critical = "mwaa_task_duration_baseline_crit" }
    mwaa_dag_duration_success = { group = "MWAA", namespace = "AmazonMWAA", metric = "DAGDurationSuccess", statistic = "Average", type = "baseline_gt", dim_key = "", warning = "mwaa_dag_duration_baseline_warn", critical = "mwaa_dag_duration_baseline_crit" }
    mwaa_write_latency        = { group = "MWAA", namespace = "AWS/MWAA", metric = "WriteLatency", statistic = "Average", type = "gt", dim_key = "", warning = "mwaa_write_latency_warn", critical = "mwaa_write_latency_crit" }
    mwaa_scheduler_heartbeat  = { group = "MWAA", namespace = "AmazonMWAA", metric = "SchedulerHeartbeat", statistic = "Sum", type = "lt", dim_key = "", warning = "mwaa_scheduler_heartbeat_warn", critical = "mwaa_scheduler_heartbeat_crit" }
    mwaa_tasks_pending        = { group = "MWAA", namespace = "AmazonMWAA", metric = "TasksPending", statistic = "Maximum", type = "gt", dim_key = "", warning = "mwaa_tasks_pending_warn", critical = "mwaa_tasks_pending_crit" }
    mwaa_running_tasks        = { group = "MWAA", namespace = "AWS/MWAA", metric = "RunningTasks", statistic = "Maximum", type = "gt", dim_key = "", warning = "mwaa_running_tasks_warn", critical = "mwaa_running_tasks_crit" }
    mwaa_queued_tasks         = { group = "MWAA", namespace = "AWS/MWAA", metric = "QueuedTasks", statistic = "Maximum", type = "gt", dim_key = "", warning = "mwaa_queued_tasks_warn", critical = "mwaa_queued_tasks_crit" }
    mwaa_import_errors        = { group = "MWAA", namespace = "AmazonMWAA", metric = "ImportErrors", statistic = "Sum", type = "gt", dim_key = "", warning = "mwaa_import_errors_warn", critical = "mwaa_import_errors_crit" }
    mwaa_task_failures        = { group = "MWAA", namespace = "AmazonMWAA", metric = "TaskInstanceFailures", statistic = "Sum", type = "gt", dim_key = "", warning = "mwaa_task_failures_warn", critical = "mwaa_task_failures_crit" }
    mwaa_zombies              = { group = "MWAA", namespace = "AmazonMWAA", metric = "ZombiesKilled", statistic = "Sum", type = "gt", dim_key = "", warning = "mwaa_zombies_warn", critical = "mwaa_zombies_crit" }
    mwaa_sla_missed           = { group = "MWAA", namespace = "AmazonMWAA", metric = "SLAMissed", statistic = "Sum", type = "gt", dim_key = "", warning = "mwaa_sla_missed_warn", critical = "mwaa_sla_missed_crit" }
    mwaa_processor_timeouts   = { group = "MWAA", namespace = "AmazonMWAA", metric = "ProcessorTimeouts", statistic = "Sum", type = "gt", dim_key = "", warning = "mwaa_processor_timeouts_warn", critical = "mwaa_processor_timeouts_crit" }
    mwaa_db_connections       = { group = "MWAA", namespace = "AWS/MWAA", metric = "DatabaseConnections", statistic = "Maximum", type = "gt", dim_key = "", warning = "mwaa_db_conn_warn", critical = "mwaa_db_conn_crit" }
    mwaa_cpu                  = { group = "MWAA", namespace = "AWS/MWAA", metric = "CPUUtilization", statistic = "Average", type = "gt", dim_key = "", warning = "mwaa_cpu_warn", critical = "mwaa_cpu_crit" }
    mwaa_memory               = { group = "MWAA", namespace = "AWS/MWAA", metric = "MemoryUtilization", statistic = "Average", type = "gt", dim_key = "", warning = "mwaa_mem_warn", critical = "mwaa_mem_crit" }
    mwaa_oldest_task          = { group = "MWAA", namespace = "AWS/MWAA", metric = "ApproximateAgeOfOldestTask", statistic = "Maximum", type = "gt", dim_key = "", warning = "mwaa_oldest_task_warn", critical = "mwaa_oldest_task_crit" }
    mwaa_pool_queued          = { group = "MWAA", namespace = "AmazonMWAA", metric = "PoolQueuedSlots", statistic = "Maximum", type = "gt", dim_key = "", warning = "mwaa_pool_queued_warn", critical = "mwaa_pool_queued_crit" }
    mwaa_critical_section     = { group = "MWAA", namespace = "AmazonMWAA", metric = "CriticalSectionBusy", statistic = "Average", type = "gt", dim_key = "", warning = "mwaa_critical_section_warn", critical = "mwaa_critical_section_crit" }
    mwaa_disk_queue           = { group = "MWAA", namespace = "AWS/MWAA", metric = "DiskQueueDepth", statistic = "Maximum", type = "gt", dim_key = "", warning = "mwaa_disk_queue_warn", critical = "mwaa_disk_queue_crit" }
    mwaa_freeable_mem         = { group = "MWAA", namespace = "AWS/MWAA", metric = "FreeableMemory", statistic = "Minimum", type = "lt", dim_key = "", warning = "mwaa_freeable_mem_warn", critical = "mwaa_freeable_mem_crit" }

    # ── Control Panel ─────────────────────────────────────────────────────────
    cp_pod_cpu_throttle  = { group = "Control Panel", namespace = "ContainerInsights", metric = "pod_cpu_utilization_over_pod_limit", statistic = "Average", type = "gt", dim_key = "Namespace", dim_key2 = "ClusterName", match_exact = true, warning = "cp_pod_cpu_throttle_warn", critical = "cp_pod_cpu_throttle_crit" }
    cp_pod_net_rx        = { group = "Control Panel", namespace = "ContainerInsights", metric = "pod_network_rx_bytes", statistic = "Sum", type = "baseline_gt", dim_key = "Namespace", dim_key2 = "ClusterName", match_exact = true, warning = "cp_pod_net_baseline_warn", critical = "cp_pod_net_baseline_crit" }
    cp_pod_net_tx        = { group = "Control Panel", namespace = "ContainerInsights", metric = "pod_network_tx_bytes", statistic = "Sum", type = "baseline_gt", dim_key = "Namespace", dim_key2 = "ClusterName", match_exact = true, warning = "cp_pod_net_baseline_warn", critical = "cp_pod_net_baseline_crit" }
    cp_pod_memory        = { group = "Control Panel", namespace = "ContainerInsights", metric = "pod_memory_utilization", statistic = "Average", type = "gt", dim_key = "Namespace", dim_key2 = "ClusterName", match_exact = true, warning = "cp_pod_mem_warn", critical = "cp_pod_mem_crit" }
    cp_pod_cpu           = { group = "Control Panel", namespace = "ContainerInsights", metric = "pod_cpu_utilization", statistic = "Average", type = "gt", dim_key = "Namespace", dim_key2 = "ClusterName", match_exact = true, warning = "cp_pod_cpu_warn", critical = "cp_pod_cpu_crit" }
    cp_pod_mem_reserved  = { group = "Control Panel", namespace = "ContainerInsights", metric = "pod_memory_reserved_capacity", statistic = "Average", type = "gt", dim_key = "Namespace", dim_key2 = "ClusterName", warning = "cp_pod_mem_reserved_warn", critical = "cp_pod_mem_reserved_crit" }
    cp_node_cpu_reserved = { group = "Control Panel", namespace = "ContainerInsights", metric = "node_cpu_reserved_capacity", statistic = "Average", type = "gt", dim_key = "NodeName", warning = "cp_node_cpu_reserved_warn", critical = "cp_node_cpu_reserved_crit" }

    # ── Redis ─────────────────────────────────────────────────────────────────
    redis_read_latency      = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "SuccessfulReadRequestLatency", statistic = "Average", type = "gt", dim_key = "", warning = "redis_read_latency_warn", critical = "redis_read_latency_crit" }
    redis_write_latency     = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "SuccessfulWriteRequestLatency", statistic = "Average", type = "gt", dim_key = "", warning = "redis_write_latency_warn", critical = "redis_write_latency_crit" }
    redis_get_latency       = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "GetTypeCmdsLatency", statistic = "Average", type = "gt", dim_key = "", warning = "redis_get_latency_warn", critical = "redis_get_latency_crit" }
    redis_curr_connections  = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "CurrConnections", statistic = "Maximum", type = "gt", dim_key = "", warning = "redis_curr_conn_warn", critical = "redis_curr_conn_crit" }
    redis_net_in            = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "NetworkBytesIn", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "redis_net_baseline_warn", critical = "redis_net_baseline_crit" }
    redis_net_out           = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "NetworkBytesOut", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "redis_net_baseline_warn", critical = "redis_net_baseline_crit" }
    redis_evictions         = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "Evictions", statistic = "Sum", type = "gt", dim_key = "", warning = "redis_evictions_warn", critical = "redis_evictions_crit" }
    redis_replication_lag   = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "ReplicationLag", statistic = "Maximum", type = "gt", dim_key = "", warning = "redis_replication_lag_warn", critical = "redis_replication_lag_crit" }
    redis_cpu               = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "EngineCPUUtilization", statistic = "Average", type = "gt", dim_key = "", warning = "redis_cpu_warn", critical = "redis_cpu_crit" }
    redis_swap              = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "SwapUsage", statistic = "Maximum", type = "gt", dim_key = "", warning = "redis_swap_warn", critical = "redis_swap_crit" }
    redis_replication_bytes = { group = "Control Panel", namespace = "AWS/ElastiCache", metric = "ReplicationBytes", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "redis_replication_bytes_warn", critical = "redis_replication_bytes_crit" }

    # ── RDS ───────────────────────────────────────────────────────────────────
    rds_read_latency         = { group = "Control Panel", namespace = "AWS/RDS", metric = "ReadLatency", statistic = "Average", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_read_latency_warn", critical = "rds_read_latency_crit" }
    rds_write_latency        = { group = "Control Panel", namespace = "AWS/RDS", metric = "WriteLatency", statistic = "Average", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_write_latency_warn", critical = "rds_write_latency_crit" }
    rds_commit_latency       = { group = "Control Panel", namespace = "AWS/RDS", metric = "CommitLatency", statistic = "Average", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_commit_latency_warn", critical = "rds_commit_latency_crit" }
    rds_db_connections       = { group = "Control Panel", namespace = "AWS/RDS", metric = "DatabaseConnections", statistic = "Maximum", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_db_conn_warn", critical = "rds_db_conn_crit" }
    rds_read_iops            = { group = "Control Panel", namespace = "AWS/RDS", metric = "ReadIOPS", statistic = "Average", type = "baseline_gt", dim_key = "DBInstanceIdentifier", warning = "rds_iops_baseline_warn", critical = "rds_iops_baseline_crit" }
    rds_write_iops           = { group = "Control Panel", namespace = "AWS/RDS", metric = "WriteIOPS", statistic = "Average", type = "baseline_gt", dim_key = "DBInstanceIdentifier", warning = "rds_iops_baseline_warn", critical = "rds_iops_baseline_crit" }
    rds_net_rx               = { group = "Control Panel", namespace = "AWS/RDS", metric = "NetworkReceiveThroughput", statistic = "Average", type = "baseline_gt", dim_key = "DBInstanceIdentifier", warning = "rds_net_baseline_warn", critical = "rds_net_baseline_crit" }
    rds_net_tx               = { group = "Control Panel", namespace = "AWS/RDS", metric = "NetworkTransmitThroughput", statistic = "Average", type = "baseline_gt", dim_key = "DBInstanceIdentifier", warning = "rds_net_baseline_warn", critical = "rds_net_baseline_crit" }
    rds_replica_lag          = { group = "Control Panel", namespace = "AWS/RDS", metric = "ReplicaLag", statistic = "Maximum", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_replica_lag_warn", critical = "rds_replica_lag_crit" }
    rds_failed_jobs          = { group = "Control Panel", namespace = "AWS/RDS", metric = "FailedSQLServerAgentJobsCount", statistic = "Sum", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_failed_jobs_warn", critical = "rds_failed_jobs_crit" }
    rds_max_tx_id            = { group = "Control Panel", namespace = "AWS/RDS", metric = "MaximumUsedTransactionIDs", statistic = "Maximum", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_max_tx_id_warn", critical = "rds_max_tx_id_crit" }
    rds_replication_slot_lag = { group = "Control Panel", namespace = "AWS/RDS", metric = "OldestReplicationSlotLag", statistic = "Maximum", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_replication_slot_lag_warn", critical = "rds_replication_slot_lag_crit" }
    rds_cpu                  = { group = "Control Panel", namespace = "AWS/RDS", metric = "CPUUtilization", statistic = "Average", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_cpu_warn", critical = "rds_cpu_crit" }
    rds_disk_queue           = { group = "Control Panel", namespace = "AWS/RDS", metric = "DiskQueueDepth", statistic = "Maximum", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_disk_queue_warn", critical = "rds_disk_queue_crit" }
    rds_burst_balance        = { group = "Control Panel", namespace = "AWS/RDS", metric = "BurstBalance", statistic = "Minimum", type = "lt", dim_key = "DBInstanceIdentifier", warning = "rds_burst_balance_warn", critical = "rds_burst_balance_crit" }
    rds_ebs_io_balance       = { group = "Control Panel", namespace = "AWS/RDS", metric = "EBSIOBalance%", statistic = "Minimum", type = "lt", dim_key = "DBInstanceIdentifier", warning = "rds_ebs_io_balance_warn", critical = "rds_ebs_io_balance_crit" }
    rds_swap                 = { group = "Control Panel", namespace = "AWS/RDS", metric = "SwapUsage", statistic = "Maximum", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_swap_warn", critical = "rds_swap_crit" }
  }
}
