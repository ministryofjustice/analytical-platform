data "aws_iam_policy_document" "airflow_create_a_pipeline" {
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    #checkov:skip=CKV_AWS_356: skip requires access to multiple resources
    sid    = "AllowListAllMyBuckets"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "AllowGetPutObject"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::aws-athena-query-results-684969100054-eu-west-1",
      "arn:aws:s3:::aws-athena-query-results-684969100054-eu-west-1/*"
    ]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    #checkov:skip=CKV_AWS_111: skip requires access to multiple resources
    sid    = "AllowGetPutDeleteObject"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::mojap-athena-query-dump-sandbox/$${aws:userid}/*"
    ]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    #checkov:skip=CKV_AWS_356: skip requires access to multiple resources
    sid    = "AllowReadAthenaGlue"
    effect = "Allow"
    actions = [
      "athena:BatchGetNamedQuery",
      "athena:BatchGetQueryExecution",
      "athena:GetNamedQuery",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:GetWorkGroup",
      "athena:ListNamedQueries",
      "athena:ListWorkGroups",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "athena:CancelQueryExecution",
      "athena:GetCatalogs",
      "athena:GetExecutionEngine",
      "athena:GetExecutionEngines",
      "athena:GetNamespace",
      "athena:GetNamespaces",
      "athena:GetTable",
      "athena:GetTables",
      "athena:RunQuery",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
      "glue:GetCatalogImportStatus",
      "glue:GetUserDefinedFunction",
      "glue:GetUserDefinedFunctions"
    ]
    resources = [
      "*"
    ]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    #checkov:skip=CKV_AWS_356: skip requires access to multiple resources
    sid    = "AllowWriteAthenaGlue"
    effect = "Allow"
    actions = [
      "athena:DeleteNamedQuery",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:BatchDeleteTable",
      "glue:CreateDatabase",
      "glue:CreatePartition",
      "glue:CreateTable",
      "glue:DeleteDatabase",
      "glue:DeletePartition",
      "glue:DeleteTable",
      "glue:UpdateDatabase",
      "glue:UpdatePartition",
      "glue:UpdateTable",
      "glue:CreateUserDefinedFunction",
      "glue:DeleteUserDefinedFunction",
      "glue:UpdateUserDefinedFunction"
    ]
    resources = [
      "*"
    ]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    sid    = "readwrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersion",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:RestoreObject",
      "s3:GetObjectAttributes"
    ]
    resources = [
      "arn:aws:s3:::alpha-hmcts-de-testing-sandbox",
      "arn:aws:s3:::alpha-hmcts-de-testing-sandbox/*"
    ]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    sid    = "list"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::mojap-athena-query-dump-sandbox",
      "arn:aws:s3:::alpha-hmcts-de-testing-sandbox",
      "arn:aws:s3:::alpha-hmcts-de-testing-sandbox/*"
    ]
  }
}

module "airflow_create_a_pipeline_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

  name_prefix = "github-airflow-create-a-pipeline"

  policy = data.aws_iam_policy_document.airflow_create_a_pipeline.json
}
