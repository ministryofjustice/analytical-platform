data "aws_iam_policy_document" "mlflow_access" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::alpha-analytical-platform-mlflow-development",
      "arn:aws:s3:::alpha-analytical-platform-mlflow-development/*",
      "arn:aws:s3:::mojap-athena-query-dump",
      "arn:aws:s3:::mojap-athena-query-dump/*"
    ]
  }

  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "athena:ListNamedQueries",
      "athena:ListWorkGroups",
      "athena:GetNamedQuery",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:GetWorkGroup",
      "athena:GetCatalogs",
      "athena:GetExecutionEngine",
      "athena:GetExecutionEngines",
      "athena:GetNamespace",
      "athena:GetNamespaces",
      "athena:GetTable",
      "athena:GetTables",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "athena:GetTableMetadata"
    ]
    resources = [
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-production"]}:datacatalog/AwsDataCatalog",
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-production"]}:workgroup/primary"
    ]
  }

  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetPartitionIndexes",
      "glue:DeleteTable",
      "glue:DeleteSchema",
      "glue:DeletePartition",
      "glue:UpdateTable",
      "glue:UpdateSchema",
      "glue:UpdatePartition",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:CreateSchema",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:BatchCreatePartition"
    ]
    resources = [
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:database/mlflow_access",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:table/mlflow_access/users",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:catalog"
    ]
  }
}

module "mlflow_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.0"

  name_prefix = "github-mlflow-access"

  policy = data.aws_iam_policy_document.mlflow_access.json
}

module "mlflow_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.54.0"

  name = "github-mlflow-access"

  subjects = ["moj-analytical-services/mlflow-access:*"]

  policies = {
    github_mlflow_access = module.mlflow_access_iam_policy.arn
  }
}
