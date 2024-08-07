#trivy:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "quicksight_author" {
  #checkov:skip=CKV_AWS_111: This is a service policy
  #checkov:skip=CKV_AWS_356: Needs to access multiple resources
  #checkov:skip=CKV_AWS_109: Needs to access multiple resources

  statement {
    sid       = "CreateAuthor"
    effect    = "Allow"
    actions   = ["quicksight:CreateUser"]
    resources = ["arn:aws:quicksight::${var.account_ids["analytical-platform-development"]}:user/$${aws:userid}"]
  }

  statement {
    sid    = "QuicksightAuthor"
    effect = "Allow"

    actions = [
      "quicksight:UpdateTemplate",
      "quicksight:ListUsers",
      "quicksight:UpdateDashboard",
      "quicksight:CreateTemplate",
      "quicksight:ListTemplates",
      "quicksight:DescribeTemplate",
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:UpdateDataSetPermissions",
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:CreateIngestion",
      "quicksight:CancelIngestion"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "quicksight_author" {
  name   = "dev-quicksight-author-access"
  policy = data.aws_iam_policy_document.quicksight_author.json
}

#trivy:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "lake_formation_data_access" {
  #checkov:skip=CKV_AWS_111: This is a service policy
  #checkov:skip=CKV_AWS_356: Needs to access multiple resources
  #checkov:skip=CKV_AWS_109: Needs to access multiple resources

  statement {
    sid       = "LakeFormationDataAccessAdditional"
    effect    = "Allow"
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lake_formation_data_access" {
  name   = "lake-formation-data-access-additional"
  policy = data.aws_iam_policy_document.lake_formation_data_access.json
}
