#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "bedrock_integration" {
  #checkov:skip=CKV_AWS_111: This is a service policy
  #checkov:skip=CKV_AWS_356: Needs to access multiple resources
  statement {
    sid    = "AnalyticalPlatformBedrockIntegration"
    effect = "Allow"

    actions = [
      "bedrock:ListFoundationModels",
      "bedrock:GetFoundationModel",
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:CreateModelCustomizationJob",
      "bedrock:GetModelCustomizationJob",
      "bedrock:GetFoundationModelAvailability",
      "bedrock:ListModelCustomizationJobs",
      "bedrock:StopModelCustomizationJob",
      "bedrock:GetCustomModel",
      "bedrock:ListCustomModels",
      "bedrock:DeleteCustomModel",
      "bedrock:ListInferenceProfiles",
      "bedrock:CreateProvisionedModelThroughput",
      "bedrock:UpdateProvisionedModelThroughput",
      "bedrock:GetProvisionedModelThroughput",
      "bedrock:DeleteProvisionedModelThroughput",
      "bedrock:ListProvisionedModelThroughputs",
      "bedrock:ListTagsForResource",
      "bedrock:UntagResource",
      "bedrock:TagResource",
      "bedrock:CreateAgent",
      "bedrock:UpdateAgent",
      "bedrock:GetAgent",
      "bedrock:ListAgents",
      "bedrock:CreateActionGroup",
      "bedrock:UpdateActionGroup",
      "bedrock:GetActionGroup",
      "bedrock:ListActionGroups",
      "bedrock:CreateAgentDraftSnapshot",
      "bedrock:GetAgentVersion",
      "bedrock:ListAgentVersions",
      "bedrock:CreateAgentAlias",
      "bedrock:UpdateAgentAlias",
      "bedrock:GetAgentAlias",
      "bedrock:ListAgentAliases",
      "bedrock:InvokeAgent",
      "bedrock:PutFoundationModelEntitlement",
      "bedrock:GetModelInvocationLoggingConfiguration",
      "bedrock:PutModelInvocationLoggingConfiguration",
      "bedrock:CreateFoundationModelAgreement",
      "bedrock:DeleteFoundationModelAgreement",
      "bedrock:ListFoundationModelAgreementOffers",
      "bedrock:GetUseCaseForModelAccess",
      "bedrock:CreateModelInvocationJob",
      "bedrock:GetModelInvocationJob",
      "bedrock:ListModelInvocationJobs",
      "bedrock:StopModelInvocationJob"
    ]

    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "eu-central-1",
        "eu-west-1",
        "eu-west-2",
        "eu-west-3",
        "us-east-1"
      ]
    }
  }
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "textract_integration" {
  #checkov:skip=CKV_AWS_111: This is a service policy
  #checkov:skip=CKV_AWS_356: Needs to access multiple resources
  statement {
    sid    = "AnalyticalPlatformTextractIntegration"
    effect = "Allow"

    actions = [
      "textract:AnalyzeDocument",
      "textract:DetectDocumentText",
      "textract:GetDocumentAnalysis",
      "textract:GetLendingAnalysis",
      "textract:ListAdapterVersions",
      "textract:AnalyzeExpense",
      "textract:GetAdapter",
      "textract:GetDocumentTextDetection",
      "textract:GetLendingAnalysisSummary",
      "textract:ListTagsForResource",
      "textract:AnalyzeID",
      "textract:GetAdapterVersion",
      "textract:GetExpenseAnalysis",
      "textract:ListAdapters",
      "textract:CreateAdapter",
      "textract:DeleteAdapterVersion",
      "textract:StartExpenseAnalysis",
      "textract:CreateAdapterResource",
      "textract:StartDocumentAnalysis",
      "textract:StartLendingAnalysis",
      "textract:DeleteAdapter",
      "textract:StartDocumentTextDetection",
      "textract:UpdateAdapter",
      "textract:TagResource",
      "textract:UntagResource",
    ]

    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "eu-west-1",
        "eu-west-2",
      ]
    }
  }
}

resource "aws_iam_policy" "bedrock_integration" {
  name        = "analytical-platform-bedrock-integration"
  description = "Permissions needed to allow access to Bedrock in Frankfurt from tooling."
  policy      = data.aws_iam_policy_document.bedrock_integration.json
}

resource "aws_iam_policy" "textract_integration" {
  name        = "analytical-platform-textract-integration"
  description = "Permissions needed to allow access to Textract from tooling."
  policy      = data.aws_iam_policy_document.textract_integration.json
}

##################################################
# Bedrock Batch Inference
##################################################

data "aws_iam_policy_document" "bedrock_batch_inference" {
  statement {
    sid     = "AllowBedrockAssumeRoleForBatchInference"
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:model-invocation-job/*"]
    }
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bedrock_batch_inference" {
  name               = "bedrock-batch-inference-role"
  description        = "IAM role for AWS Bedrock to perform batch inference tasks as part of model invocation workflows."
  assume_role_policy = data.aws_iam_policy_document.bedrock_batch_inference.json
}

resource "aws_iam_role_policy_attachment" "bedrock_batch_inference" {
  role       = aws_iam_role.bedrock_batch_inference.name
  policy_arn = aws_iam_policy.bedrock_integration.arn
}

# Bedrock Batch Inference s3 access
data "aws_iam_policy_document" "bedrock_batch_inference_s3_access" {
  statement {
    sid    = "bedrock-batch-inference-s3-access"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

resource "aws_iam_policy" "bedrock_batch_inference_s3_access" {
  name        = "bedrock-batch-inference-s3-access"
  description = "S3 access policy for Bedrock batch inference."
  policy      = data.aws_iam_policy_document.bedrock_batch_inference_s3_access.json
}

