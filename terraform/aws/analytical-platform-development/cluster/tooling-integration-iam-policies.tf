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
      "bedrock:GetModelInvocationLoggingConfiguration",
      "bedrock:PutModelInvocationLoggingConfiguration",
      "bedrock:CreateModelInvocationJob",
      "bedrock:GetModelInvocationJob",
      "bedrock:ListModelInvocationJobs",
      "bedrock:GetInferenceProfiles",
      "bedrock:StopModelInvocationJob",
      "aws-marketplace:ViewSubscriptions"
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

#trivy:ignore:aws-iam-no-policy-wildcards
#trivy:ignore:AVD-AWS-0342
data "aws_iam_policy_document" "comprehend_integration" {
  #checkov:skip=CKV_AWS_111: This is a service policy
  #checkov:skip=CKV_AWS_356: Needs to access multiple resources
  #checkov:skip=CKV_AWS_109: Needs to access multiple resources

  statement {
    sid    = "AnalyticalPlatformComprehendIntegration"
    effect = "Allow"
    actions = [
      "comprehend:DetectEntities",
      "comprehend:DetectKeyPhrases",
      "comprehend:DetectDominantLanguage",
      "comprehend:DetectSentiment",
      "comprehend:DetectTargetedSentiment",
      "comprehend:DetectSyntax",
      "comprehend:StartDominantLanguageDetectionJob",
      "comprehend:StartEntitiesDetectionJob",
      "comprehend:StartKeyPhrasesDetectionJob",
      "comprehend:StartSentimentDetectionJob",
      "comprehend:StartTargetedSentimentDetectionJob",
      "comprehend:StartTopicsDetectionJob",
      "comprehend:DescribeTopicsDetectionJob",
      "comprehend:ListTopicsDetectionJobs",
      "comprehend:DescribeEntitiesDetectionJob",
      "comprehend:ListEntitiesDetectionJobs",
      "comprehend:DescribeSentimentDetectionJob",
      "comprehend:ListSentimentDetectionJobs",
      "comprehend:DescribeTargetedSentimentDetectionJob",
      "comprehend:ListTargetedSentimentDetectionJobs",
      "comprehend:DescribeDominantLanguageDetectionJob",
      "comprehend:ListDominantLanguageDetectionJobs",
      "comprehend:DescribeKeyPhrasesDetectionJob",
      "comprehend:ListKeyPhrasesDetectionJobs",
      "textract:DetectDocumentText",
      "textract:AnalyzeDocument",
      "comprehend:ContainsPiiEntities",
      "comprehend:DetectPiiEntities",
      "comprehend:ListDocumentClassifiers",
      "comprehend:ListEntityRecognizers",
      "comprehend:ListDocumentClassifierSummaries"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "eu-west-1",
        "eu-west-2"
      ]
    }
  }

  statement {
    sid       = "ComprehendPassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/comprehend-batch-processing-role"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["comprehend.amazonaws.com"]
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

resource "aws_iam_policy" "comprehend_integration" {
  name        = "analytical-platform-comprehend-integration"
  description = "Permissions needed to use Comprehend APIs and pass batch processing role."
  policy      = data.aws_iam_policy_document.comprehend_integration.json
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
    sid    = "BedrockBatchInferenceS3Access"
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

# Bedrock Batch Inference cross region
data "aws_iam_policy_document" "bedrock_batch_inference_cross_region" {
  statement {
    sid    = "CrossRegionInference"
    effect = "Allow"

    actions = [
      "bedrock:InvokeModel"
    ]

    resources = [
      "arn:aws:bedrock:*::inference-profile/*",
      "arn:aws:bedrock:*::foundation-model/*"
    ]
  }
}

resource "aws_iam_policy" "bedrock_batch_inference_s3_access" {
  name        = "bedrock-batch-inference-s3-access"
  description = "S3 access policy for Bedrock batch inference."
  policy      = data.aws_iam_policy_document.bedrock_batch_inference_s3_access.json
}

resource "aws_iam_policy" "bedrock_batch_inference_cross_region" {
  name        = "bedrock-batch-inference-cross-region"
  description = "Cross region policy for Bedrock batch inference."
  policy      = data.aws_iam_policy_document.bedrock_batch_inference_cross_region.json
}

resource "aws_iam_role_policy_attachment" "bedrock_batch_inference_s3_access" {
  role       = aws_iam_role.bedrock_batch_inference.name
  policy_arn = aws_iam_policy.bedrock_batch_inference_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "bedrock_batch_inference_cross_region" {
  role       = aws_iam_role.bedrock_batch_inference.name
  policy_arn = aws_iam_policy.bedrock_batch_inference_cross_region.arn
}
