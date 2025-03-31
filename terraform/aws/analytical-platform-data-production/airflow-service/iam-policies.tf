data "aws_iam_policy_document" "athena_read" {
  #checkov:skip=CKV_AWS_111:This code is ported from IAM Builder
  #checkov:skip=CKV_AWS_356:This code is ported from IAM Builder

  statement {
    sid    = "AthenaReadOnlyS3BucketActions"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
  statement {
    sid     = "AthenaReadOnlyS3ListBuckets"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::alpha-athena-query-dump",
      "arn:aws:s3:::moj-analytics-lookup-tables",
      "arn:aws:s3:::mojap-athena-query-dump"
    ]
  }
  statement {
    sid       = "AthenaReadOnlyS3GetObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::moj-analytics-lookup-tables/*"]
  }
  statement {
    sid    = "AthenaReadOnlyS3GetPutObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::aws-athena-query-results-*"]
  }
  statement {
    sid    = "AthenaReadOnlyS3DeleteGetPutObjects"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::alpha-athena-query-dump/$${aws:userid}/*",
      "arn:aws:s3:::mojap-athena-query-dump/$${aws:userid}/*"
    ]
  }
  statement {
    sid    = "AthenaReadOnlyAthenaGlueRead"
    effect = "Allow"
    actions = [
      "athena:BatchGetNamedQuery",
      "athena:BatchGetQueryExecution",
      "athena:CancelQueryExecution",
      "athena:GetCatalogs",
      "athena:GetExecutionEngine",
      "athena:GetExecutionEngines",
      "athena:GetNamedQuery",
      "athena:GetNamespace",
      "athena:GetNamespaces",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:GetTable",
      "athena:GetTableMetadata",
      "athena:GetTables",
      "athena:GetWorkGroup",
      "athena:ListNamedQueries",
      "athena:ListQueryExecutions",
      "athena:ListWorkGroups",
      "athena:RunQuery",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "glue:BatchGetPartition",
      "glue:GetCatalogImportStatus",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetTableVersions",
      "glue:GetTables",
      "glue:GetUserDefinedFunction",
      "glue:GetUserDefinedFunctions"
    ]
    resources = ["*"]
  }
}

module "athena_read_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.0"

  path   = "/airflow-service/"
  name   = "athena-read"
  policy = data.aws_iam_policy_document.athena_read.json
}

data "aws_iam_policy_document" "athena_write" {
  #checkov:skip=CKV_AWS_111:This code is ported from IAM Builder
  #checkov:skip=CKV_AWS_356:This code is ported from IAM Builder

  statement {
    sid    = "AthenaWrite"
    effect = "Allow"
    actions = [
      "athena:DeleteNamedQuery",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:BatchDeleteTable",
      "glue:CreateDatabase",
      "glue:CreatePartition",
      "glue:CreateTable",
      "glue:CreateUserDefinedFunction",
      "glue:DeleteDatabase",
      "glue:DeletePartition",
      "glue:DeleteTable",
      "glue:DeleteUserDefinedFunction",
      "glue:UpdateDatabase",
      "glue:UpdatePartition",
      "glue:UpdateTable",
      "glue:UpdateUserDefinedFunction"
    ]
    resources = ["*"]
  }
}

module "athena_write_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.0"

  path   = "/airflow-service/"
  name   = "athena-write"
  policy = data.aws_iam_policy_document.athena_write.json
}

data "aws_iam_policy_document" "bedrock" {
  statement {
    sid    = "Bedrock"
    effect = "Allow"
    actions = [
      "bedrock:CreateActionGroup",
      "bedrock:CreateAgent",
      "bedrock:CreateAgentAlias",
      "bedrock:CreateAgentDraftSnapshot",
      "bedrock:CreateFoundationModelAgreement",
      "bedrock:CreateModelCustomizationJob",
      "bedrock:DeleteCustomModel",
      "bedrock:DeleteFoundationModelAgreement",
      "bedrock:GetActionGroup",
      "bedrock:GetAgent",
      "bedrock:GetAgentAlias",
      "bedrock:GetAgentVersion",
      "bedrock:GetCustomModel",
      "bedrock:GetFoundationModel",
      "bedrock:GetFoundationModelAvailability",
      "bedrock:GetModelCustomizationJob",
      "bedrock:GetModelInvocationLoggingConfiguration",
      "bedrock:GetUseCaseForModelAccess",
      "bedrock:InvokeAgent",
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:ListActionGroups",
      "bedrock:ListAgentAliases",
      "bedrock:ListAgents",
      "bedrock:ListAgentVersions",
      "bedrock:ListCustomModels",
      "bedrock:ListFoundationModelAgreementOffers",
      "bedrock:ListFoundationModels",
      "bedrock:ListModelCustomizationJobs",
      "bedrock:ListProvisionedModelThroughputs",
      "bedrock:ListTagsForResource",
      "bedrock:PutFoundationModelEntitlement",
      "bedrock:PutModelInvocationLoggingConfiguration",
      "bedrock:StopModelCustomizationJob",
      "bedrock:TagResource",
      "bedrock:UntagResource",
      "bedrock:UpdateActionGroup",
      "bedrock:UpdateAgent",
      "bedrock:UpdateAgentAlias"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "eu-central-1", // Frankfurt
        "eu-west-1",    // Ireland
        "eu-west-2",    // London
        "eu-west-3"     // Paris
      ]
    }
  }
}

module "bedrock_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.0"

  path   = "/airflow-service/"
  name   = "bedrock"
  policy = data.aws_iam_policy_document.bedrock.json
}

data "aws_iam_policy_document" "glue" {
  #checkov:skip=CKV_AWS_111:This code is ported from IAM Builder
  #checkov:skip=CKV_AWS_356:This code is ported from IAM Builder

  statement {
    sid    = "GlueActions"
    effect = "Allow"
    actions = [
      "glue:BatchGetJobs",
      "glue:BatchStopJobRun",
      "glue:CreateJob",
      "glue:DeleteJob",
      "glue:GetJob",
      "glue:GetJobBookmark",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:GetJobs",
      "glue:ListJobs",
      "glue:StartJobRun",
      "glue:UpdateJob"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GlueLogs"
    effect = "Allow"
    actions = [
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:GetLogEvents",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GlueMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:ListDashboards",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GlueS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::aws-glue-*/*",
      "arn:aws:s3:::*/*aws-glue-*/*",
      "arn:aws:s3:::aws-glue-*"
    ]
  }
}

module "glue_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.0"

  path   = "/airflow-service/"
  name   = "glue"
  policy = data.aws_iam_policy_document.glue.json
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid     = "DefaultKMS"
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    resources = [
      module.secrets_manager_kms.key_arn,
      module.secrets_manager_eu_west_1_replica_kms.key_arn
    ]
  }
}

module "kms_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.0"

  path   = "/airflow-service/"
  name   = "kms"
  policy = data.aws_iam_policy_document.kms.json
}
