locals {
  defaults = {
    # -------------------------------------------------------------------------
    # NAT Gateway
    # -------------------------------------------------------------------------

    # Traffic: Data coming in from VPC clients — Warning > 4 GB/min, Critical > 8 GB/min
    natgw_bytes_warn = 4294967296
    natgw_bytes_crit = 8589934592

    # Traffic: Packets received from VPC clients — Warning > 5M packets/min, Critical > 10M packets/min
    natgw_packets_warn = 5000000
    natgw_packets_crit = 10000000

    # Traffic: Number of connection attempts made — Warning > 100K/min, Critical > 200K/min
    natgw_conn_attempt_warn = 100000
    natgw_conn_attempt_crit = 200000

    # Traffic: Number of connections successfully made — Warning Baseline +50%, Critical Baseline +100%
    natgw_active_conn_warn = 500000
    natgw_active_conn_crit = 900000

    # Errors: Too many connections; ports exhausted — Warning > 0, Critical > 10/min
    natgw_port_alloc_warn = 0
    natgw_port_alloc_crit = 10

    # Errors: Packets lost by the gateway — Warning > 0, Critical > 100/min
    natgw_pkt_drop_warn = 0
    natgw_pkt_drop_crit = 100

    # Saturation: Highest throughput burst in a minute — Warning > 800 MB/s, Critical > 1 GB/s
    natgw_peak_bytes_warn = 838860800
    natgw_peak_bytes_crit = 1073741824

    # Saturation: Highest packet rate burst in a minute — Warning > 8M pps, Critical > 10M pps
    natgw_peak_pkts_warn = 8000000
    natgw_peak_pkts_crit = 10000000

    # Traffic: Number of connections successfully established — Warning Baseline +50%, Critical Baseline +100%
    natgw_conn_est_baseline_warn = 50
    natgw_conn_est_baseline_crit = 100

    # Errors: Stale connections not closed cleanly — Warning Baseline +50%, Critical Baseline +200%
    natgw_idle_timeout_baseline_warn = 50
    natgw_idle_timeout_baseline_crit = 200

    # -------------------------------------------------------------------------
    # Transit Gateway
    # -------------------------------------------------------------------------

    # Traffic: Data in/out of the gateway — Warning Baseline +50%, Critical Baseline +100%
    tgw_traffic_baseline_warn = 50
    tgw_traffic_baseline_crit = 100

    # Errors: Packets dropped — missing route entry — Warning > 0, Critical > 100/min
    tgw_pkt_drop_no_route_warn = 0
    tgw_pkt_drop_no_route_crit = 100

    # Errors: Packets dropped — hit a blackhole route — Warning > 0, Critical > 10/min
    tgw_pkt_drop_blackhole_warn = 0
    tgw_pkt_drop_blackhole_crit = 10

    # Errors: Packets dropped — TTL expired; possible routing loop — Warning > 0, Critical > 50/min
    tgw_pkt_drop_ttl_warn = 0
    tgw_pkt_drop_ttl_crit = 50

    # Errors: Bytes lost — no matching route — Warning > 0, Critical > 1 MB/min
    tgw_bytes_drop_no_route_warn = 0
    tgw_bytes_drop_no_route_crit = 1048576

    # Errors: Bytes lost — blackhole route misconfiguration — Warning > 0, Critical > 1 MB/min
    tgw_bytes_drop_blackhole_warn = 0
    tgw_bytes_drop_blackhole_crit = 1048576

    # -------------------------------------------------------------------------
    # EKS
    # -------------------------------------------------------------------------

    # Latency: API and deployments become slow (admission webhook p99) — Warning > 1s, Critical > 5s
    eks_webhook_latency_warn = 1
    eks_webhook_latency_crit = 5

    # Traffic: Total network bytes in/out of nodes — Warning > 500 MB/min, Critical > 1 GB/min
    eks_node_net_warn = 500000000
    eks_node_net_crit = 1000000000

    # Errors: Pods are not reachable (unhealthy NLB hosts) — Warning >= 1, Critical > 20% of targets
    eks_unhealthy_host_warn = 1
    eks_unhealthy_host_crit = 20

    # Errors: App is dropping connections (TCP resets) — Warning > 10/min, Critical > 100/min
    eks_tcp_reset_warn = 10
    eks_tcp_reset_crit = 100

    # Errors: Containers keep restarting — Warning > 5/hour, Critical > 20/hour
    eks_container_restart_warn = 5
    eks_container_restart_crit = 20

    # Errors: Nodes failed; less capacity — Warning >= 1, Critical > 10% of nodes
    eks_failed_node_warn = 1
    eks_failed_node_crit = 10

    # Errors: Pods cannot be placed anywhere (UNSCHEDULABLE) — Warning >= 1 for > 5 min, Critical >= 1 for > 15 min
    eks_pending_pod_warn = 1
    eks_pending_pod_crit = 1

    # Saturation: Node CPU too high — Warning > 70%, Critical > 90%
    eks_node_cpu_warn = 70
    eks_node_cpu_crit = 90

    # Saturation: Node memory full — Warning > 75%, Critical > 90%
    eks_node_mem_warn = 75
    eks_node_mem_crit = 90

    # Saturation: Node disk full — Warning > 75%, Critical > 90%
    eks_node_disk_warn = 75
    eks_node_disk_crit = 90

    # Saturation: CPU throttling; requests slow — Warning > 10% throttle, Critical > 25% throttle
    eks_pod_cpu_throttle_warn = 10
    eks_pod_cpu_throttle_crit = 25

    # Saturation: Pod killed due to memory limit — Warning > 90% of limit, Critical at or exceeding limit
    eks_pod_mem_limit_warn = 90
    eks_pod_mem_limit_crit = 100

    # Saturation: etcd size — cluster may stop accepting changes — Warning > 1.5 GB, Critical > 1.9 GB
    eks_etcd_size_warn = 1610612736
    eks_etcd_size_crit = 2040109465

    # -------------------------------------------------------------------------
    # EFS
    # -------------------------------------------------------------------------

    # Latency: Filesystem becomes slow (PercentIOLimit) — Warning > 80%, Critical > 95%
    efs_io_limit_warn = 80
    efs_io_limit_crit = 95

    # Traffic: Max allowed throughput — Warning > 80% of limit, Critical > 95% of limit
    efs_throughput_warn = 80
    efs_throughput_crit = 95

    # Traffic: Data usage level — Warning Baseline +50%, Critical Baseline +100%
    efs_metered_io_baseline_warn = 50
    efs_metered_io_baseline_crit = 100

    # Traffic: Number of connected clients — Warning Baseline +50%, Critical Baseline +100%
    efs_client_conn_baseline_warn = 50
    efs_client_conn_baseline_crit = 100

    # Saturation: Burst credit balance (zero = performance drops) — Warning < 10% of max, Critical < 1% of max
    efs_burst_credit_warn = 10
    efs_burst_credit_crit = 1

    # -------------------------------------------------------------------------
    # S3
    # -------------------------------------------------------------------------

    # Latency: Total request latency (p99) — Warning > 200ms, Critical > 1000ms
    s3_latency_total_warn = 200
    s3_latency_total_crit = 1000

    # Latency: Slow to start response (first byte p99) — Warning > 100ms, Critical > 500ms
    s3_latency_first_byte_warn = 100
    s3_latency_first_byte_crit = 500

    # Traffic: Total requests baseline — Warning Baseline +100%, Critical Baseline +300%
    s3_requests_baseline_warn = 100
    s3_requests_baseline_crit = 300

    # Traffic: Data leaving S3 — Warning Baseline +50%, Critical Baseline +200%
    s3_bytes_dl_baseline_warn = 50
    s3_bytes_dl_baseline_crit = 200

    # Errors: S3 failed requests (5xx) — Warning > 0.1% of requests, Critical > 1% of requests
    s3_5xx_warn = 1
    s3_5xx_crit = 10

    # Errors: Bad requests from app (4xx) — Warning > 1% of requests, Critical > 5% of requests
    s3_4xx_warn = 10
    s3_4xx_crit = 50

    # Saturation: Storage growing — Warning > 80% of budget, Critical > 95% of budget
    s3_bucket_size_warn = 80
    s3_bucket_size_crit = 95

    # Saturation: Too many objects — Warning > 1 billion, Critical > 2 billion
    s3_object_count_warn = 1000000000
    s3_object_count_crit = 2000000000

    # -------------------------------------------------------------------------
    # MWAA (Managed Airflow)
    # -------------------------------------------------------------------------

    # Latency: Scheduler busy reading DAGs — Warning > 30s, Critical > 60s
    mwaa_parse_time_warn = 30
    mwaa_parse_time_crit = 60

    # Latency: DAGs not processed recently — Warning > 60s, Critical > 300s
    mwaa_dag_processing_age_warn = 60
    mwaa_dag_processing_age_crit = 300

    # Latency: Tasks running longer than usual — Warning Baseline +50%, Critical Baseline +100%
    mwaa_task_duration_baseline_warn = 50
    mwaa_task_duration_baseline_crit = 100

    # Latency: Pipeline runtime increased — Warning Baseline +50%, Critical Baseline +100%
    mwaa_dag_duration_baseline_warn = 50
    mwaa_dag_duration_baseline_crit = 100

    # Latency: Database writes are slow — Warning > 20ms, Critical > 100ms
    mwaa_write_latency_warn = 20
    mwaa_write_latency_crit = 100

    # Traffic: Scheduler heartbeat; if zero, scheduler is down — Warning < 1 in 30s, Critical = 0
    mwaa_scheduler_heartbeat_warn = 1
    mwaa_scheduler_heartbeat_crit = 0

    # Traffic: Tasks waiting to start — Warning > 50, Critical > 200
    mwaa_tasks_pending_warn = 50
    mwaa_tasks_pending_crit = 200

    # Traffic: Tasks currently running — Warning > 80% of max workers, Critical > 95% of max workers
    mwaa_running_tasks_warn = 80
    mwaa_running_tasks_crit = 95

    # Traffic: Tasks waiting for workers — Warning > 50, Critical > 200
    mwaa_queued_tasks_warn = 50
    mwaa_queued_tasks_crit = 200

    # Errors: DAGs failing to load — Warning >= 1, Critical > 5
    mwaa_import_errors_warn = 1
    mwaa_import_errors_crit = 5

    # Errors: Tasks failing — Warning > 1% of tasks, Critical > 5% of tasks
    mwaa_task_failures_warn = 1
    mwaa_task_failures_crit = 5

    # Errors: Stuck tasks cleaned up — Warning >= 1/hour, Critical > 5/hour
    mwaa_zombies_warn = 1
    mwaa_zombies_crit = 5

    # Errors: Tasks missed deadlines — Warning >= 1, Critical > 5
    mwaa_sla_missed_warn = 1
    mwaa_sla_missed_crit = 5

    # Errors: DAG parsing timed out — Warning >= 1/hour, Critical > 3/hour
    mwaa_processor_timeouts_warn = 1
    mwaa_processor_timeouts_crit = 3

    # Saturation: Too many DB connections — Warning > 80% of max, Critical > 95% of max
    mwaa_db_conn_warn = 80
    mwaa_db_conn_crit = 95

    # Saturation: Workers overloaded (CPU) — Warning > 70%, Critical > 90%
    mwaa_cpu_warn = 70
    mwaa_cpu_crit = 90

    # Saturation: Memory pressure — Warning > 75%, Critical > 90%
    mwaa_mem_warn = 75
    mwaa_mem_crit = 90

    # Saturation: Tasks waiting too long — Warning > 10 min, Critical > 30 min
    mwaa_oldest_task_warn = 600
    mwaa_oldest_task_crit = 1800

    # Saturation: Tasks stuck in pools — Warning > 50, Critical > 200
    mwaa_pool_queued_warn = 50
    mwaa_pool_queued_crit = 200

    # Saturation: Scheduler contention — Warning > 50% busy, Critical > 80% busy
    mwaa_critical_section_warn = 50
    mwaa_critical_section_crit = 80

    # Saturation: Database overloaded (disk queue depth) — Warning > 10, Critical > 50
    mwaa_disk_queue_warn = 10
    mwaa_disk_queue_crit = 50

    # Saturation: Low DB memory (freeable) — Warning < 256 MB, Critical < 64 MB
    mwaa_freeable_mem_warn = 268435456
    mwaa_freeable_mem_crit = 67108864

    # -------------------------------------------------------------------------
    # Control Panel
    # -------------------------------------------------------------------------

    # Latency: Requests become slow (pod CPU throttling over limit) — Warning > 80% of limit, Critical > 95% of limit
    cp_pod_cpu_throttle_warn = 80
    cp_pod_cpu_throttle_crit = 95

    # Traffic: Network traffic in/out of pods — Warning Baseline +50%, Critical Baseline +100%
    cp_pod_net_baseline_warn = 50
    cp_pod_net_baseline_crit = 100

    # Saturation: Pod memory getting high — Warning > 75%, Critical > 90%
    cp_pod_mem_warn = 75
    cp_pod_mem_crit = 90

    # Saturation: Pod CPU getting high — Warning > 70%, Critical > 90%
    cp_pod_cpu_warn = 70
    cp_pod_cpu_crit = 90

    # Saturation: No memory left for new pods (reserved capacity) — Warning > 75%, Critical > 90%
    cp_pod_mem_reserved_warn = 75
    cp_pod_mem_reserved_crit = 90

    # Saturation: No CPU left for new pods (node reserved capacity) — Warning > 70%, Critical > 90%
    cp_node_cpu_reserved_warn = 70
    cp_node_cpu_reserved_crit = 90

    # -------------------------------------------------------------------------
    # Redis (ElastiCache)
    # -------------------------------------------------------------------------

    # Latency: Reads are slow — Warning > 1ms, Critical > 5ms
    redis_read_latency_warn = 1
    redis_read_latency_crit = 5

    # Latency: Writes are slow — Warning > 2ms, Critical > 10ms
    redis_write_latency_warn = 2
    redis_write_latency_crit = 10

    # Latency: Specific GET command slow — Warning > 1ms, Critical > 5ms
    redis_get_latency_warn = 1
    redis_get_latency_crit = 5

    # Traffic: Network data in/out — Warning Baseline +50%, Critical Baseline +100%
    redis_net_baseline_warn = 50
    redis_net_baseline_crit = 100

    # Traffic: Number of active connections — Warning > 10K, Critical > 50K
    redis_curr_conn_warn = 10000
    redis_curr_conn_crit = 50000

    # Errors: Keys removed due to memory pressure — Warning > 0, Critical > 1000/min
    redis_evictions_warn = 0
    redis_evictions_crit = 1000

    # Errors: Replica falling behind — Warning > 1s, Critical > 10s
    redis_replication_lag_warn = 1
    redis_replication_lag_crit = 10

    # Saturation: Redis overloaded (engine CPU) — Warning > 65%, Critical > 90%
    redis_cpu_warn = 65
    redis_cpu_crit = 90

    # Saturation: Using swap — very slow — Warning > 50 MB, Critical > 100 MB
    redis_swap_warn = 52428800
    redis_swap_crit = 104857600

    # Saturation: High replication load — Warning Baseline +50%, Critical Baseline +100%
    redis_replication_bytes_warn = 50
    redis_replication_bytes_crit = 100

    # -------------------------------------------------------------------------
    # RDS
    # -------------------------------------------------------------------------

    # Latency: Reads are slow — Warning > 5ms, Critical > 20ms
    rds_read_latency_warn = 5
    rds_read_latency_crit = 20

    # Latency: Writes are slow — Warning > 5ms, Critical > 20ms
    rds_write_latency_warn = 5
    rds_write_latency_crit = 20

    # Latency: Transactions slow (commit latency) — Warning > 10ms, Critical > 50ms
    rds_commit_latency_warn = 10
    rds_commit_latency_crit = 50

    # Traffic: Number of DB connections — Warning > 80% of max_connections, Critical > 95% of max_connections
    rds_db_conn_warn = 80
    rds_db_conn_crit = 95

    # Traffic: Read/Write IOPS activity — Warning Baseline +50%, Critical Baseline +100%
    rds_iops_baseline_warn = 50
    rds_iops_baseline_crit = 100

    # Traffic: Incoming/outgoing network throughput — Warning Baseline +50%, Critical Baseline +100%
    rds_net_baseline_warn = 50
    rds_net_baseline_crit = 100

    # Errors: Replica falling behind — Warning > 30s, Critical > 300s
    rds_replica_lag_warn = 30
    rds_replica_lag_crit = 300

    # Errors: Jobs failing (SQL Server only) — Warning >= 1, Critical > 3
    rds_failed_jobs_warn = 1
    rds_failed_jobs_crit = 3

    # Errors: Risk of transaction ID wraparound (PostgreSQL) — Warning > 1.5 billion, Critical > 1.9 billion
    rds_max_tx_id_warn = 1500000000
    rds_max_tx_id_crit = 1900000000

    # Errors: WAL logs building up (oldest replication slot lag) — Warning > 1 GB, Critical > 5 GB
    rds_replication_slot_lag_warn = 1073741824
    rds_replication_slot_lag_crit = 5368709120

    # Saturation: CPU too high — Warning > 70%, Critical > 90%
    rds_cpu_warn = 70
    rds_cpu_crit = 90

    # Saturation: Storage cannot keep up (disk queue depth) — Warning > 10, Critical > 50
    rds_disk_queue_warn = 10
    rds_disk_queue_crit = 50

    # Saturation: I/O burst credits used up — Warning < 20%, Critical < 5%
    rds_burst_balance_warn = 20
    rds_burst_balance_crit = 5

    # Saturation: EBS storage burst limit reached — Warning < 20%, Critical < 5%
    rds_ebs_io_balance_warn = 20
    rds_ebs_io_balance_crit = 5

    # Saturation: Using swap — very slow — Warning > 256 MB, Critical > 1 GB
    rds_swap_warn = 268435456
    rds_swap_crit = 1073741824
  }

  thresholds = {
    for env, cfg in local.environment_configurations :
    env => merge(local.defaults, try(cfg.threshold_overrides, {}))
  }
}
