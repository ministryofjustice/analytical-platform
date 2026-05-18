locals {
  namespaces_regex_by_env = {
    for env, cfg in local.environment_configurations :
    env => join("|", [
      for ns in try(cfg.namespaces, ["cpanel"]) :
      ns if length(regexall("^[a-z0-9-]+$", ns)) > 0
    ])
  }

  dims_by_combo = {
    for env, cfg in local.environment_configurations :
    env => {
      for combo_key, combo in local.rule_combos_by_env[env] :
      combo_key => (
        try(combo.rule.dim_key2, "") != "" ? {
          (combo.rule.dim_key)  = [combo.dim_value]
          (combo.rule.dim_key2) = ["*"]
        } :
        combo.dim_value != "" ? {
          (combo.rule.dim_key) = [combo.dim_value]
        } :
        {}
      )
    }
  }

  rule_combos_by_env = {
    for env, cfg in local.environment_configurations :
    env => {
      for combo in flatten([
        for rule_key, rule in local.golden_signals : [
          for dim_value in(
            rule.dim_key == "CacheClusterId" ? try(cfg.cache_clusters, []) :
            rule.dim_key == "BucketName" ? try(cfg.s3_buckets, []) :
            rule.dim_key == "DBInstanceIdentifier" ? try(cfg.rds_instances, []) :
            rule.dim_key == "Namespace" ? try(cfg.namespaces, ["cpanel"]) :
            rule.dim_key == "ClusterName" ? ["*"] :
            rule.dim_key == "NodeName" ? ["*"] :
            [""]
            ) : {
            rule_key  = rule_key
            rule      = rule
            dim_value = dim_value
            suffix    = dim_value != "" ? "_${dim_value}" : ""
          }
        ]
      ]) : "${combo.rule_key}${combo.suffix}" => combo
    }
  }

  sc_resolved = {
    for env, cfg in local.environment_configurations :
    env => {
      for combo_key, combo in local.rule_combos_by_env[env] :
      combo_key => {
        for severity in ["warning", "critical"] :
        severity => (
          try(combo.rule.slack_channel[severity], null) != null
          ? combo.rule.slack_channel[severity]
          : try(tostring(combo.rule.slack_channel), null) != null && try(tostring(combo.rule.slack_channel), null) != "null"
          ? tostring(combo.rule.slack_channel)
          : try(cfg.slack_channel, null)
        )
      }
    }
  }

  rule_yaml = {
    for env, cfg in local.environment_configurations :
    env => {
      for combo_key, combo in local.rule_combos_by_env[env] :
      combo_key => {
        for severity in ["warning", "critical"] :
        severity => join("\n", compact(flatten([
          # ── rule header ──────────────────────────────────────────────────────
          [
            "      - title: ${combo_key}_${severity}",
            "        uid: ${substr(md5("${env}-${combo_key}-${severity}"), 0, 8)}",
            "        condition: ${contains(["baseline_gt", "baseline_lt"], combo.rule.type) ? "D" : "C"}",
            "        for: ${try(combo.rule.for_duration, "5m")}",
            "        noDataState: ${try(combo.rule.ok_when_nodata, false) ? "OK" : "NoData"}",
            "        labels:",
            "          severity: ${severity}",
            "          environment: ${env}",
            "          service: ${lower(replace(combo.rule.group, " ", "_"))}",
            "          metric: ${combo.rule.metric}",
            (
              local.sc_resolved[env][combo_key][severity] != null
              ? "          slack-channel: ${local.sc_resolved[env][combo_key][severity]}"
              : null
            ),
            "        data:",
          ],
          # ── A: data query — CloudWatch time-series OR Prometheus instant ─────
          try(combo.rule.datasource_type, "cloudwatch") == "prometheus" ? [
            "          - refId: A",
            "            relativeTimeRange:",
            "              from: 300",
            "              to: 0",
            "            datasourceUid: ${try(cfg.prometheus_datasource_uid, try(cfg.prometheus_datasource_name, "prometheus"))}",
            "            model:",
            "              type: instant",
            "              refId: A",
            "              expr: '${replace(combo.rule.expr, "__NAMESPACES__", local.namespaces_regex_by_env[env])}'",
            "              instant: true",
            "              range: false",
            ] : [
            "          - refId: A",
            "            relativeTimeRange:",
            "              from: 300",
            "              to: 0",
            "            datasourceUid: ${substr(cfg.cloudwatch_datasource_name, 0, 40)}",
            "            model:",
            "              type: timeSeriesQuery",
            "              refId: A",
            "              region: ${try(cfg.aws_region, var.aws_region)}",
            "              namespace: ${combo.rule.namespace}",
            "              metricName: ${combo.rule.metric}",
            "              statistic: ${combo.rule.statistic}",
            "              period: '60'",
            "              dimensions: ${jsonencode(local.dims_by_combo[env][combo_key])}",
            "              matchExact: ${try(combo.rule.dim_key2, "") != "" ? true : try(combo.rule.match_exact, false)}",
          ],

          # ── B: reduce A to a single scalar ───────────────────────────────────
          [
            "          - refId: B",
            "            datasourceUid: __expr__",
            "            relativeTimeRange:",
            "              from: 300",
            "              to: 0",
            "            model:",
            "              type: reduce",
            "              refId: B",
            "              expression: A",
            "              reducer: last",
            "              settings:",
            "                mode: dropNN",
          ],

          # ── C: threshold check ───────────────────────────────────────────────
          [
            "          - refId: C",
            "            datasourceUid: __expr__",
            "            relativeTimeRange:",
            "              from: 300",
            "              to: 0",
            "            model:",
            "              type: threshold",
            "              refId: C",
            "              expression: B",
            "              conditions:",
            "                - evaluator:",
            "                    type: ${contains(["lt", "baseline_lt"], combo.rule.type) ? "lt" : "gt"}",
            "                    params:",
            "                      - ${local.thresholds[env][severity == "warning" ? combo.rule.warning : combo.rule.critical]}",
          ],
          # ── BASE / BASE_R / D: only for baseline CloudWatch alert types ────────
          contains(["baseline_gt", "baseline_lt"], combo.rule.type) && try(combo.rule.datasource_type, "cloudwatch") != "prometheus" ? [

            "          - refId: BASE",
            "            relativeTimeRange:",
            "              from: 3600",
            "              to: 0",
            "            datasourceUid: ${substr(cfg.cloudwatch_datasource_name, 0, 40)}",
            "            model:",
            "              type: timeSeriesQuery",
            "              refId: BASE",
            "              region: ${try(cfg.aws_region, var.aws_region)}",
            "              namespace: ${combo.rule.namespace}",
            "              metricName: ${combo.rule.metric}",
            "              statistic: Average",
            "              period: '3600'",
            "              dimensions: ${jsonencode(local.dims_by_combo[env][combo_key])}",
            "              matchExact: ${try(combo.rule.dim_key2, "") != "" ? true : try(combo.rule.match_exact, false)}",

            "          - refId: BASE_R",
            "            datasourceUid: __expr__",
            "            relativeTimeRange:",
            "              from: 3600",
            "              to: 0",
            "            model:",
            "              type: reduce",
            "              refId: BASE_R",
            "              expression: BASE",
            "              reducer: last",
            "              settings:",
            "                mode: dropNN",

            "          - refId: D",
            "            datasourceUid: __expr__",
            "            relativeTimeRange:",
            "              from: 3600",
            "              to: 0",
            "            model:",
            "              type: math",
            "              refId: D",
            "              expression: ${combo.rule.type == "baseline_lt" ? "$BASE_R > 0 && ($B - $BASE_R) / $BASE_R * 100 < -${local.thresholds[env][severity == "warning" ? combo.rule.warning : combo.rule.critical]}" : "$BASE_R > 0 && ($B - $BASE_R) / $BASE_R * 100 > ${local.thresholds[env][severity == "warning" ? combo.rule.warning : combo.rule.critical]}"}",
          ] : [],

          [""],
        ])))
      }
    }
  }

  group_blocks_by_env = {
    for env, cfg in local.environment_configurations :
    env => [
      for group in cfg.enabled_groups :
      join("\n", concat(
        [
          "  - name: ${env}-${local.group_folders[group].name_suffix}",
          "    folder: ${local.group_folders[group].folder}",
          "    interval: ${try(cfg.evaluation_interval, var.evaluation_interval)}",
          "    editable: true",
          "    rules:",
        ],
        flatten([
          for combo_key, combo in local.rule_combos_by_env[env] :
          combo.rule.group == group ? [
            local.rule_yaml[env][combo_key]["warning"],
            local.rule_yaml[env][combo_key]["critical"],
          ] : []
        ])
      ))
      if anytrue([
        for combo_key, combo in local.rule_combos_by_env[env] : combo.rule.group == group
      ])
    ]
  }
}
