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
