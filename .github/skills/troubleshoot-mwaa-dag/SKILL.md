---
name: troubleshoot-mwaa-dag
description: "Troubleshoot Airflow DAG pod issues in the mwaa Kubernetes namespace. Use when: a user reports a failing DAG, stuck pod, pod errors, or wants to check the status of a running MWAA workflow. Covers pod inspection, log analysis, process debugging, and workload-specific deep dives (dbt, Python scripts, etc.)."
argument-hint: "DAG name or pod name to troubleshoot"
---

# Troubleshoot MWAA DAG

Diagnose issues with Airflow DAG pods running in the `mwaa` Kubernetes namespace.

## When to Use

- A DAG run has failed or is stuck
- A user asks to check the status of a running DAG
- A pod is taking longer than expected
- A previous run failed and the user wants to monitor a retry
- Investigating pod errors, OOM kills, or scheduling issues
## Procedure

### Step 1: Identify the Pod

If the user provides a pod name, use it directly. Otherwise, find pods for the DAG:

```shell
kubectl get pods -n mwaa -l dag_id=<dag-id> --sort-by=.metadata.creationTimestamp
```

If the DAG ID is unknown, search by workflow label:

```shell
kubectl get pods -n mwaa -l airflow.compute.analytical-platform.service.justice.gov.uk/workflow=<workflow-name>
```

Or list recent pods:

```shell
kubectl get pods -n mwaa --sort-by=.metadata.creationTimestamp | tail -20
```

### Step 2: Get Pod Overview

```shell
kubectl get pod <pod-name> -n mwaa -o wide
kubectl describe pod <pod-name> -n mwaa
```

Key things to note:

- **Status**: Running, Succeeded, Failed, Error, OOMKilled
- **Restart count**: Non-zero suggests crashes
- **Resource requests/limits**: CPU and memory (check for OOM risk)
- **Labels**: `dag_id`, `run_id`, `task_id`, `try_number`
- **Environment variables**: Check all env vars to understand what the pod is running — look for `MODE`, `DEPLOY_ENV`, `BRANCH`, and any workload-specific variables (e.g., `DBT_SELECT_CRITERIA`, `THREAD_COUNT` for dbt pods)
- **Image**: Note the container image to understand the workload type
- **Events**: Look for scheduling issues, image pull errors, node pressure

### Step 3: Check Logs (stdout)

```shell
kubectl logs <pod-name> -n mwaa --tail=100
```

For a completed/failed pod, get all logs:

```shell
kubectl logs <pod-name> -n mwaa
```

If the pod has restarted (restart count > 0 from Step 2, e.g., after an OOMKill), the current container's logs may be empty or only show the latest attempt. Retrieve the **previous** container's logs:

```shell
kubectl logs <pod-name> -n mwaa --previous --tail=100
```

Look for:

- Error messages or stack traces
- Progress indicators (varies by workload)
- The last meaningful output and when it occurred

If logs appear stale, check whether there has been any recent output:

```shell
kubectl logs <pod-name> -n mwaa --since=10m
```

### Step 4: Check Process State (Running Pods Only)

Verify the main process is alive and inspect resource usage:

```shell
kubectl exec <pod-name> -n mwaa -- ps aux
```

Note the main process PID, then inspect its state:

```shell
kubectl exec <pod-name> -n mwaa -- cat /proc/<PID>/status | grep -E "Threads|State|VmRSS"
```

- **State S (sleeping)**: Normal — typically waiting on network I/O
- **State R (running)**: Actively computing
- **VmRSS**: Resident memory in kB — compare to pod memory limit
- **Threads**: Compare to expected concurrency

### Step 5: Check for Log Files Inside the Container

Some workloads write detailed logs to files rather than stdout. Search for log files:

```shell
kubectl exec <pod-name> -n mwaa -- find / -name "*.log" -newer /proc/1/cmdline 2>/dev/null | head -10
```

Then tail any relevant log files:

```shell
kubectl exec <pod-name> -n mwaa -- tail -80 <log-file-path>
```

### Step 6: Search for Errors

Check stdout logs and any internal log files for errors:

```shell
kubectl logs <pod-name> -n mwaa | grep -i "error\|exception\|fail\|traceback" | tail -20
```

If you found internal log files in Step 5:

```shell
kubectl exec <pod-name> -n mwaa -- grep -i "error\|exception\|fail\|traceback" <log-file-path> | tail -20
```

### Step 7: Workload-Specific Deep Dive

Based on what you learned from the image, environment variables, and logs, apply workload-specific debugging.

#### dbt Pods (CaDeT)

Identified by: image containing `cadet-deployer`, env vars like `DBT_SELECT_CRITERIA`, `THREAD_COUNT`, `DBT_PROJECT`, `DBT_PROFILE_WORKGROUP`.

**dbt log file location:**

```shell
kubectl exec <pod-name> -n mwaa -- tail -80 /opt/analyticalplatform/create-a-derived-table/mojap_derived_tables/logs/dbt.log
```

**Track dbt progress** — count started vs completed models:

```shell
kubectl exec <pod-name> -n mwaa -- grep -E "\[info \].*of [0-9]+ START" /opt/analyticalplatform/create-a-derived-table/mojap_derived_tables/logs/dbt.log | wc -l
kubectl exec <pod-name> -n mwaa -- grep -E "\[info \].*of [0-9]+ (OK|PASS|FAIL|ERROR)" /opt/analyticalplatform/create-a-derived-table/mojap_derived_tables/logs/dbt.log | wc -l
```

**Identify stuck threads** — check each thread's last activity (replace N with 1 through `THREAD_COUNT`):

```shell
kubectl exec <pod-name> -n mwaa -- grep "Thread-N" /opt/analyticalplatform/create-a-derived-table/mojap_derived_tables/logs/dbt.log | tail -5
```

**Track Athena queries:**

```shell
kubectl exec <pod-name> -n mwaa -- grep "Athena query ID" /opt/analyticalplatform/create-a-derived-table/mojap_derived_tables/logs/dbt.log | tail -10
```

Large time gaps between a query submission and the next log entry indicate an Athena query is still executing.

#### Python Script Pods

Identified by: image or entrypoint running a Python script directly.

Check for Python-specific errors:

```shell
kubectl logs <pod-name> -n mwaa | grep -i "traceback\|error\|exception" | tail -20
```

#### Generic / Unknown Workloads

Inspect the entrypoint to understand what the pod is doing:

```shell
kubectl exec <pod-name> -n mwaa -- cat /proc/1/cmdline | tr '\0' ' '
```

Check filesystem activity:

```shell
kubectl exec <pod-name> -n mwaa -- find /tmp -type f -mmin -5 2>/dev/null | head -10
```

## Common Issues

### OOMKilled

**Symptoms**: Pod status shows OOMKilled or restart count > 0.

**Cause**: Main process consuming more memory than the pod limit. Check `resources.limits.memory` from `describe` output and compare to `VmRSS` from `/proc/<PID>/status`.

### Image Pull Errors

**Symptoms**: Pod stuck in `ImagePullBackOff` or `ErrImagePull`.

**Cause**: ECR authentication expired, image tag doesn't exist, or registry unreachable. Check Events in `describe` output.

### Pod Stuck in Pending

**Symptoms**: Pod never reaches Running state.

**Cause**: No nodes match the pod's tolerations/node selectors, or insufficient cluster capacity. Check Events and tolerations in `describe` output.

### No Log Output but Pod Running

**Symptoms**: Pod is Running but logs are empty or stale.

**Cause**: The workload may be blocked on an external dependency (e.g., waiting for an Athena query, an API call, or a database connection). Check process state and internal log files.

### dbt-Specific: Incremental Models Running for Hours

**Symptoms**: dbt threads stuck since the start; stdout shows no progress but pod is Running.

**Cause**: Incremental models (e.g., `sirius_preprocessed`) doing full table scans. Check thread-level logs for `"S3 path does not exist"` — this means the target table is missing, forcing a full rebuild.

**Impact**: Long-running models consume threads. Once all other parallelisable work finishes, dbt blocks waiting for these threads.

### dbt-Specific: Athena Query Timeout

**Symptoms**: Model fails after ~30 minutes.

**Cause**: Athena has DML/CTAS query time limits. Very large queries can exceed this.

## Reporting

When summarising findings to the user, include:

1. **Pod status** and how long it has been running
2. **Workload type** and what it is doing
3. **Progress**: Any measurable progress indicators
4. **What is currently happening**: Active processes, recent log output
5. **Identified issues**: Errors, stuck processes, resource pressure
6. **Likely cause and next steps**
