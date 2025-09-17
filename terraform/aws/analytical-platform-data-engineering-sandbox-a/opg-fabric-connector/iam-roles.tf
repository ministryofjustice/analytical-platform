resource "aws_iam_role" "entra_role" {
  name               = "opg-entra-oidc-s3"
  assume_role_policy = data.aws_iam_policy_document.entra_trust.json
}