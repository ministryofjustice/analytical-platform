resource "aws_iam_role" "opg_fabric_access" {
  name               = "opg-fabric-s3"
  assume_role_policy = data.aws_iam_policy_document.opg_fabric_trust.json
}
