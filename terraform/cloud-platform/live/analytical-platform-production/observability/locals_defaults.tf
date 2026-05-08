locals {
  defaults = {
    # NAT Gateway
    natgw_bytes_warn                 = 4294967296
    natgw_bytes_crit                 = 8589934592
    natgw_packets_warn               = 5000000
    natgw_packets_crit               = 10000000
    natgw_conn_attempt_warn          = 100000
    natgw_conn_attempt_crit          = 200000
    natgw_active_conn_warn           = 500000
    natgw_active_conn_crit           = 900000
    natgw_port_alloc_warn            = 0
    natgw_port_alloc_crit            = 10
    natgw_pkt_drop_warn              = 0
    natgw_pkt_drop_crit              = 100
    natgw_peak_bytes_warn            = 838860800
    natgw_peak_bytes_crit            = 1073741824
    natgw_peak_pkts_warn             = 8000000
    natgw_peak_pkts_crit             = 10000000
    natgw_conn_est_baseline_warn     = 50
    natgw_conn_est_baseline_crit     = 100
    natgw_idle_timeout_baseline_warn = 50
    natgw_idle_timeout_baseline_crit = 200

    # Transit Gateway
    tgw_traffic_baseline_warn     = 50
    tgw_traffic_baseline_crit     = 100
    tgw_pkt_drop_no_route_warn    = 0
    tgw_pkt_drop_no_route_crit    = 100
    tgw_pkt_drop_blackhole_warn   = 0
    tgw_pkt_drop_blackhole_crit   = 10
    tgw_pkt_drop_ttl_warn         = 0
    tgw_pkt_drop_ttl_crit         = 50
    tgw_bytes_drop_no_route_warn  = 0
    tgw_bytes_drop_no_route_crit  = 1048576
    tgw_bytes_drop_blackhole_warn = 0
    tgw_bytes_drop_blackhole_crit = 1048576

    # EKS
    eks_webhook_latency_warn   = 1
    eks_webhook_latency_crit   = 5
    eks_node_net_baseline_warn = 50
    eks_node_net_baseline_crit = 100
    eks_unhealthy_host_warn    = 1
    eks_unhealthy_host_crit    = 20
    eks_tcp_reset_warn         = 10
    eks_tcp_reset_crit         = 100
    eks_container_restart_warn = 5
    eks_container_restart_crit = 20
    eks_failed_node_warn       = 1
    eks_failed_node_crit       = 10
    eks_pending_pod_warn       = 1
    eks_pending_pod_crit       = 1
    eks_node_cpu_warn          = 70
    eks_node_cpu_crit          = 90
    eks_node_mem_warn          = 75
    eks_node_mem_crit          = 90
    eks_node_disk_warn         = 75
    eks_node_disk_crit         = 90
    eks_pod_cpu_throttle_warn  = 10
    eks_pod_cpu_throttle_crit  = 25
    eks_pod_mem_limit_warn     = 90
    eks_pod_mem_limit_crit     = 100
    eks_etcd_size_warn         = 1610612736
    eks_etcd_size_crit         = 2040109465

    # EFS
    efs_io_limit_warn             = 80
    efs_io_limit_crit             = 95
    efs_throughput_warn           = 80
    efs_throughput_crit           = 95
    efs_metered_io_baseline_warn  = 50
    efs_metered_io_baseline_crit  = 100
    efs_client_conn_baseline_warn = 50
    efs_client_conn_baseline_crit = 100
    efs_burst_credit_warn         = 10
    efs_burst_credit_crit         = 1

    # S3
    s3_latency_total_warn      = 200
    s3_latency_total_crit      = 1000
    s3_latency_first_byte_warn = 100
    s3_latency_first_byte_crit = 500
    s3_requests_baseline_warn  = 100
    s3_requests_baseline_crit  = 300
    s3_bytes_dl_baseline_warn  = 50
    s3_bytes_dl_baseline_crit  = 200
    s3_5xx_warn                = 1
    s3_5xx_crit                = 10
    s3_4xx_warn                = 10
    s3_4xx_crit                = 50
    s3_bucket_size_warn        = 80
    s3_bucket_size_crit        = 95
    s3_object_count_warn       = 1000000000
    s3_object_count_crit       = 2000000000

    # MWAA
    mwaa_parse_time_warn             = 30
    mwaa_parse_time_crit             = 60
    mwaa_dag_processing_age_warn     = 60
    mwaa_dag_processing_age_crit     = 300
    mwaa_task_duration_baseline_warn = 50
    mwaa_task_duration_baseline_crit = 100
    mwaa_dag_duration_baseline_warn  = 50
    mwaa_dag_duration_baseline_crit  = 100
    mwaa_write_latency_warn          = 20
    mwaa_write_latency_crit          = 100
    mwaa_scheduler_heartbeat_warn    = 1
    mwaa_scheduler_heartbeat_crit    = 0
    mwaa_tasks_pending_warn          = 50
    mwaa_tasks_pending_crit          = 200
    mwaa_running_tasks_warn          = 80
    mwaa_running_tasks_crit          = 95
    mwaa_queued_tasks_warn           = 50
    mwaa_queued_tasks_crit           = 200
    mwaa_import_errors_warn          = 1
    mwaa_import_errors_crit          = 5
    mwaa_task_failures_warn          = 1
    mwaa_task_failures_crit          = 5
    mwaa_zombies_warn                = 1
    mwaa_zombies_crit                = 5
    mwaa_sla_missed_warn             = 1
    mwaa_sla_missed_crit             = 5
    mwaa_processor_timeouts_warn     = 1
    mwaa_processor_timeouts_crit     = 3
    mwaa_db_conn_warn                = 80
    mwaa_db_conn_crit                = 95
    mwaa_cpu_warn                    = 70
    mwaa_cpu_crit                    = 90
    mwaa_mem_warn                    = 75
    mwaa_mem_crit                    = 90
    mwaa_oldest_task_warn            = 600
    mwaa_oldest_task_crit            = 1800
    mwaa_pool_queued_warn            = 50
    mwaa_pool_queued_crit            = 200
    mwaa_critical_section_warn       = 50
    mwaa_critical_section_crit       = 80
    mwaa_disk_queue_warn             = 10
    mwaa_disk_queue_crit             = 50
    mwaa_freeable_mem_warn           = 268435456
    mwaa_freeable_mem_crit           = 67108864

    # Control Panel
    cp_pod_cpu_throttle_warn  = 80
    cp_pod_cpu_throttle_crit  = 95
    cp_pod_net_baseline_warn  = 50
    cp_pod_net_baseline_crit  = 100
    cp_pod_mem_warn           = 75
    cp_pod_mem_crit           = 90
    cp_pod_cpu_warn           = 70
    cp_pod_cpu_crit           = 90
    cp_pod_mem_reserved_warn  = 75
    cp_pod_mem_reserved_crit  = 90
    cp_node_cpu_reserved_warn = 70
    cp_node_cpu_reserved_crit = 90

    # Redis
    redis_read_latency_warn      = 1
    redis_read_latency_crit      = 5
    redis_write_latency_warn     = 2
    redis_write_latency_crit     = 10
    redis_get_latency_warn       = 1
    redis_get_latency_crit       = 5
    redis_net_baseline_warn      = 50
    redis_net_baseline_crit      = 100
    redis_curr_conn_warn         = 10000
    redis_curr_conn_crit         = 50000
    redis_evictions_warn         = 0
    redis_evictions_crit         = 1000
    redis_replication_lag_warn   = 1
    redis_replication_lag_crit   = 10
    redis_cpu_warn               = 65
    redis_cpu_crit               = 90
    redis_swap_warn              = 52428800
    redis_swap_crit              = 104857600
    redis_replication_bytes_warn = 50
    redis_replication_bytes_crit = 100

    # RDS
    rds_read_latency_warn         = 5
    rds_read_latency_crit         = 20
    rds_write_latency_warn        = 5
    rds_write_latency_crit        = 20
    rds_commit_latency_warn       = 10
    rds_commit_latency_crit       = 50
    rds_db_conn_warn              = 80
    rds_db_conn_crit              = 95
    rds_iops_baseline_warn        = 50
    rds_iops_baseline_crit        = 100
    rds_net_baseline_warn         = 50
    rds_net_baseline_crit         = 100
    rds_replica_lag_warn          = 30
    rds_replica_lag_crit          = 300
    rds_failed_jobs_warn          = 1
    rds_failed_jobs_crit          = 3
    rds_max_tx_id_warn            = 1500000000
    rds_max_tx_id_crit            = 1900000000
    rds_replication_slot_lag_warn = 1073741824
    rds_replication_slot_lag_crit = 5368709120
    rds_cpu_warn                  = 70
    rds_cpu_crit                  = 90
    rds_disk_queue_warn           = 10
    rds_disk_queue_crit           = 50
    rds_burst_balance_warn        = 20
    rds_burst_balance_crit        = 5
    rds_ebs_io_balance_warn       = 20
    rds_ebs_io_balance_crit       = 5
    rds_swap_warn                 = 268435456
    rds_swap_crit                 = 1073741824
  }

  thresholds = {
    for env, cfg in local.environment_configurations :
    env => merge(local.defaults, try(cfg.threshold_overrides, {}))
  }
}
