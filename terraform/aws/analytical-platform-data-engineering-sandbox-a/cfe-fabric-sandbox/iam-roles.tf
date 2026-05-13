resource "aws_iam_role" "cfe_fabric_access" {
  name               = "cfe-fabric-s3"
  assume_role_policy = data.aws_iam_policy_document.cfe_fabric_trust.json
}
