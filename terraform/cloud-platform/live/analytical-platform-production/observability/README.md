# Observability

Terraform module that deploys a single Grafana instance and manages it as code:

- **Alert rules** — generated from a compact "golden signals" definition, deployed across AWS accounts and their resources, and provisioned into Grafana as file-based alert-rule YAML.
- **Dashboards** — JSON files under `src/helm/values/grafana/dashboards/`, provisioned into matching Grafana folders via the same file-provisioning mechanism.
- **Datasources / contact points / notification policies** — defined directly in the Grafana Helm chart's values (`src/helm/values/grafana/values.yml.tftpl`).

One Grafana instance monitors all AP AWS accounts, each via its own CloudWatch/Prometheus datasource. `environment_configurations` is the per-*account* alerting configuration, not a per-environment Grafana deployment — there's only one Grafana here, in `analytical-platform-production`.

## List of files

```text
terraform.tf                 Backend config and provider blocks (aws, github,
                              kubernetes, helm).

variables.tf                 Module inputs — see "Module inputs" below.

data.tf                      Data sources: cluster credentials, Secrets
                              Manager (GitHub OAuth, Slack token), GitHub teams
                              used for the Grafana admin role mapping.

locals_environments.tf       environment_configurations — per-AWS-account
                              alerting config: which datasource(s) it uses,
                              which alert groups are enabled, resource lists
                              for dimension fan-out, threshold overrides,
                              disabled rules, evaluation interval.

locals_golden_signals.tf     The alert catalogue: group_folders (group name ->
                              Grafana folder) and golden_signals (one entry
                              per metric/signal).

locals_defaults.tf           defaults — threshold values (warning/critical)
                              referenced by golden_signals above. thresholds
                              merges defaults with each account's
                              threshold_overrides.

locals_rules.tf               It's the main golden_signals alerts creation,
                              environment_configurations into one Grafana
                              alert rule per resource/account/severity —
                              CloudWatch/Prometheus query pipeline, Slack
                              routing/urgency, baseline math. Nothing here
                              needs editing to add a new alert.

locals_dashboards.tf          Every dashboard JSON file under
                              src/helm/values/grafana/dashboards/<folder>/ and
                              builds the dashboardProviders/dashboards values
                              passed into the Helm release. Nothing here needs
                              editing to add a new dashboard.

main.tf                      Renders golden_signals + environment_configurations
                              into per-account alert-rule YAML, then creates one
                              ConfigMap per account (grafana_alert_rules) holding
                              it.

helm-releases.tf             Deploys the Grafana Helm release, wiring in
                              values.yml.tftpl plus the ConfigMap names/
                              checksums main.tf and locals_dashboards.tf
                              produced.

src/helm/values/grafana/
  values.yml.tftpl            The Grafana Helm chart values: datasources (one
                               per monitored AWS account, hand-maintained —
                               see "Datasources" below), contact points/
                               notification policies, dashboardProviders, and
                               the extraVolumes/extraVolumeMounts that mount
                               the alert-rule ConfigMaps into the pod.
  dashboards/<folder>/*.json  Dashboard JSON files, one subfolder per Grafana
                               folder (see "Dashboards" below).
```

## Module inputs (`variables.tf`)

| Variable | Type | Default | Description |
| --- | --- | --- | --- |
| `account_ids` | `map(string)` | — (required) | Account name → account ID. |
| `tags` | `map(string)` | — (required) | Tags applied to resources. |
| `namespace` | `string` | — (required) | Kubernetes namespace Grafana is deployed into. |
| `aws_region` | `string` | `"eu-west-2"` | Region used for CloudWatch queries when an account doesn't set its own `aws_region`. |
| `evaluation_interval` | `string` | `"1m"` | Rule-evaluation interval used when an account doesn't set its own `evaluation_interval`. |

Set in `terraform.tfvars`.

### Alert rules

Alert rules are created with file provisioning:

1. `locals_rules.tf` renders `golden_signals` × `environment_configurations` into Grafana's native alert-provisioning YAML shape.
2. `main.tf` YAML-encodes that per account and puts it in a `kubernetes_config_map_v1.grafana_alert_rules` ConfigMap (one per account, keyed `rules.yaml`), with a `checksum/rules` annotation.
3. `values.yml.tftpl` mounts each account's ConfigMap into the Grafana pod under `/etc/grafana/provisioning/alerting/rules-<account>.yaml`, and stamps the checksum onto `podAnnotations` so a content change forces a pod restart and picks up the new rules.
4. A Postgres purge `initContainer` deletes any alert rule left in Grafana's database whose UID isn't in the currently-mounted files — so removing a rule from `golden_signals`/an account's config actually removes it from Grafana, not just stops updating it.

Nothing in `locals_rules.tf` or `main.tf` needs to change to add a new alert or account — day-to-day changes happen in `locals_golden_signals.tf`, `locals_defaults.tf`, and `locals_environments.tf`.

### Dashboards

Any `.json` file dropped under `dashboards/<folder>/` is picked up automatically — `locals_dashboards.tf` discovers the files at plan time and builds the `dashboardProviders`/`dashboards` Helm values from them.

## Adding a new alert or group

### 1. Add a new group (only if the alert doesn't fit an existing one)

Groups map to a Grafana folder and give the rule group a name suffix. Add an entry to `group_folders` in `locals_golden_signals.tf`:

```hcl
group_folders = {
  "S3"            = { folder = "internal/compute/storage", name_suffix = "s3" }
  "Control Panel" = { folder = "internal/compute/cluster",  name_suffix = "cpanel" }
}
```

- `folder` — the Grafana folder path the rule group is filed under.
- `name_suffix` — appended to `<account>-` to build the Grafana rule group name (e.g. `analytical-platform-compute-production-s3`).

A group only produces rules once it's also switched on for an account (step 3).

### 2. Add the golden signal

Add an entry to `golden_signals` in `locals_golden_signals.tf`. Each key is the alert's base name — for `dim_key`-fanned-out rules, the resolved dimension value gets appended automatically (e.g. `s3_5xx_errors_my-bucket-name`), so write the key without it.

**CloudWatch example** — RDS CPU, one rule per RDS instance:

```hcl
rds_cpu = { group = "Control Panel", namespace = "AWS/RDS", metric = "CPUUtilization", statistic = "Average", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_cpu_warn", critical = "rds_cpu_crit" }
```

**Prometheus example** — no CloudWatch dimension, one rule per configured namespace:

```hcl
cp_crashloop_backoff = { group = "Control Panel", datasource_type = "prometheus", expr = "count by (namespace, pod) (kube_pod_container_status_waiting_reason{reason=\"CrashLoopBackOff\", namespace=~\"__NAMESPACES__\"})", type = "gt", dim_key = "", metric = "crashloop_backoff", ok_when_nodata = true, warning = "cp_crashloop_warn", critical = "cp_crashloop_crit" }
```

**Baseline example** — fires on a % deviation from the trailing hourly baseline instead of a fixed threshold (good for traffic/throughput metrics with no sensible fixed number):

```hcl
natgw_BytesInFromSource = { group = "NAT Gateway", namespace = "AWS/NATGateway", metric = "BytesInFromSource", statistic = "Sum", type = "baseline_gt", dim_key = "", warning = "natgw_bytes_warn", critical = "natgw_bytes_crit" }
```

Then add matching threshold keys to `defaults` in `locals_defaults.tf`:

```hcl
rds_cpu_warn = 70  # % CPU — warning
rds_cpu_crit = 90  # % CPU — critical
```

Both `warning` and `critical` must be set — the engine always generates both severities unconditionally, with no fallback if a key is missing. There's no "single-severity" option here.

### 3. Enable the group for an account

Add the group name to `enabled_groups` for the relevant account(s) in `locals_environments.tf`:

```hcl
analytical-platform-compute-production = {
  cloudwatch_datasource_name = "mojap-compute-production-cloudwatch"
  enabled_groups             = ["NAT Gateway", "EKS", "S3"]
  s3_buckets                 = ["mojap-compute-production-mwaa", "mojap-compute-production-velero"]
}
```

## Golden signal variables

Every key inside `golden_signals` (in `locals_golden_signals.tf`) is one of the fields below, with why it exists.

| Field | Required | Description |
| --- | --- | --- |
| `group` | yes | Must match a key in `group_folders`. |
| `namespace` | CloudWatch only | CloudWatch namespace, e.g. `AWS/RDS`. |
| `metric` | yes | CloudWatch metric name, or the label used for Prometheus signals. |
| `statistic` | CloudWatch only | `Sum`, `Average`, `Maximum`, `Minimum`, `p99`, etc. |
| `datasource_type` | no | Set to `"prometheus"` to query Prometheus via `expr` instead of CloudWatch. |
| `expr` | Prometheus only | PromQL query. `__NAMESPACES__` is replaced with the account's `namespaces`, joined by `&#124;`. |
| `type` | yes | `gt` fires above threshold, `lt` fires below, `baseline_gt`/`baseline_lt` fire on % deviation from an hourly baseline. |
| `dim_key` | yes | Dimension to fan the rule out over — one rule per value. `""` = single global rule. |
| `dim_key2` | no | Second dimension, always matched to `"*"`. |
| `match_exact` | no (default `false`) | If `true`, only returns series matching the dimension set exactly. |
| `use_metric_math` | no (default `false`) | If `true`, evaluates the threshold against `A / A2 * 100` instead of the raw metric. |
| `capacity_metric` | with `use_metric_math` | Metric used as the denominator (`A2`). |
| `capacity_statistic` | no (default `"Minimum"`) | Statistic applied to the capacity metric. |
| `ok_when_nodata` | no (default `true`) | If true, no data resolves to Normal and doesn't notify Slack. If false, no data pages as NoData. |
| `for_duration` | no (default `"5m"`) | How long the condition must hold before firing. |
| `query_window_seconds` | no (default `300`) | Lookback window for the current-value queries. |
| `baseline_window_seconds` | no (default `3600`) | Lookback window and period for the baseline pipeline. |
| `urgency` | no | Slack urgency: `"high"` / `"medium"` / `"low"`, or an object per severity. Overrides the default routing matrix. |
| `slack_notify` | no (default `true`) | If false, routes to the silent contact point — rule still evaluates, just doesn't page Slack. |
| `warning` | yes | Threshold key for the warning severity. |
| `critical` | yes | Threshold key for the critical severity. Both required. |

### Supported `dim_key` values

| `dim_key` | Resolves against (per account, in `locals_environments.tf`) |
| --- | --- |
| `""` | No dimension filter — a single global aggregate rule. |
| `BucketName` | `s3_buckets` |
| `DBInstanceIdentifier` | `rds_instances` |
| `CacheClusterId` | `cache_clusters` |
| `Namespace` | `namespaces` (defaults to `["cpanel"]` if unset) |
| `FileSystemId` | `efs_file_systems` |
| `ClusterName`, `NodeName`, `TargetGroup`, `DAG`, `LoadBalancer`,`ModelId` | `["*"]` — wildcard, not resolved from account config |

Any other `dim_key` value resolves to `[""]` (no rule generated) — extend the `dim_value` conditional in `locals_rules.tf`'s `rule_combos_by_env` to add a new dimension type.

## Account configuration fields (`environment_configurations`)

Each key in `environment_configurations` (in `locals_environments.tf`) is one AWS account's alerting configuration.

| Field | Required | Default | Description |
| --- | --- | --- | --- |
| `cloudwatch_datasource_name` | for any CloudWatch-sourced rule | — | Grafana datasource used for this account's CloudWatch rules. |
| `prometheus_datasource_name` | for any Prometheus-sourced rule | — | Grafana datasource used for this account's Prometheus rules. |
| `aws_region` | no | `var.aws_region` | AWS region CloudWatch queries run against. |
| `enabled_groups` | no | `[]` | Groups that get rules for this account. A group not listed here produces zero rules. |
| `disabled_rules` | no | `[]` | Specific signal keys to skip for this account, even if their group is enabled. |
| `s3_buckets` | with `BucketName`-dimensioned rules | `[]` | Bucket names to fan `BucketName` rules out over. |
| `rds_instances` | with `DBInstanceIdentifier`-dimensioned rules | `[]` | RDS instance IDs to fan `DBInstanceIdentifier` rules out over. |
| `cache_clusters` | with `CacheClusterId`-dimensioned rules | `[]` | Cache cluster IDs to fan `CacheClusterId` rules out over. |
| `namespaces` | with `Namespace`-dimensioned rules, and any Prometheus signal using `__NAMESPACES__` | `["cpanel"]` | K8s namespaces — used both for `Namespace` fan-out and substituted into Prometheus `expr`. |
| `efs_file_systems` | with `FileSystemId`-dimensioned rules | `[]` | Filesystem IDs to fan `FileSystemId` rules out over. |
| `threshold_overrides` | no | `{}` | Threshold keys to override for this account only. |
| `evaluation_interval` | no | `var.evaluation_interval` | How often this account's rules are evaluated. |

### Examples

**`disabled_rules`** — turn off specific golden signals for one account, even if their group is enabled:

```hcl
disabled_rules = ["cp_crashloop_backoff", "rds_cpu"]
```

**`threshold_overrides`** — tighten or loosen a threshold for one account only:

```hcl
threshold_overrides = {
  cp_pod_net_baseline_warn = 5
}
```

**`evaluation_interval`** — evaluate this account's rules less often:

```hcl
evaluation_interval = "5m"
```

## Adding a dashboard

Drop a dashboard JSON into a subfolder of `src/helm/values/grafana/dashboards/`:

```text
src/helm/values/grafana/dashboards/<folder>/<dashboard-name>.json
```

- `<folder>` becomes the Grafana UI folder name (used as-is — no title-casing) and its own provisioning provider.
- `<dashboard-name>` becomes the dashboard's key within that folder (the `.json` extension is stripped).
