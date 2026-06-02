resource "aws_iam_role" "replication" {
  for_each = local.replication_configurations

  name               = "${each.value.source_bucket_name}-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_trust.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  for_each = local.replication_configurations

  role       = aws_iam_role.replication[each.key].name
  policy_arn = aws_iam_policy.replication[each.key].arn
}
