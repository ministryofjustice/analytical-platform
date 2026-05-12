resource "aws_iam_role" "replication" {
  for_each = local.enabled_replication_configurations

  name               = "${each.value.source_bucket_name}-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_trust.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  for_each = local.enabled_replication_configurations

  role       = aws_iam_role.replication[each.key].name
  policy_arn = aws_iam_policy.replication[each.key].arn
}


moved {
  from = aws_iam_role.alpha_mojap_ho_data_transfer_replication
  to   = aws_iam_role.replication["test"]
}

moved {
  from = aws_iam_policy.alpha_mojap_ho_data_transfer_replication
  to   = aws_iam_policy.replication["test"]
}

moved {
  from = aws_iam_role_policy_attachment.alpha_mojap_ho_data_transfer_replication
  to   = aws_iam_role_policy_attachment.replication["test"]
}
