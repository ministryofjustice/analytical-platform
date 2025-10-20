#trivy:ignore:aws-iam-no-policy-wildcards
#trivy:ignore:AVD-AWS-0342 passing of role is needed for batch processing
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
      "bedrock:GetInferenceProfile",
      "bedrock:DeleteInferenceProfile",
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
        "us-east-1",
        "eu-north-1",
        "eu-south-1",
        "eu-south-2"
      ]
    }
  }
  statement {
    sid       = "BedrockBatchInferenceListRoles"
    effect    = "Allow"
    actions   = ["iam:ListRoles"]
    resources = ["*"]
  }
  statement {
    sid       = "BedrockPassBatchInferenceRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/bedrock-batch-inference-role"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["bedrock.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "bedrock_integration" {
  name        = "analytical-platform-bedrock-integration"
  description = "Permissions needed to allow access to Bedrock in Frankfurt from tooling."
  policy      = data.aws_iam_policy_document.bedrock_integration.json
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

resource "aws_iam_policy" "bedrock_batch_inference_s3_access" {
  name        = "bedrock-batch-inference-s3-access"
  description = "S3 access policy for Bedrock batch inference."
  policy      = data.aws_iam_policy_document.bedrock_batch_inference_s3_access.json
}

resource "aws_iam_role_policy_attachment" "bedrock_batch_inference_s3_access" {
  role       = aws_iam_role.bedrock_batch_inference.name
  policy_arn = aws_iam_policy.bedrock_batch_inference_s3_access.arn
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

resource "aws_iam_policy" "textract_integration" {
  name        = "analytical-platform-textract-integration"
  description = "Permissions needed to allow access to Textract from tooling."
  policy      = data.aws_iam_policy_document.textract_integration.json
}

#trivy:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "quicksight_author" {
  #checkov:skip=CKV_AWS_111: This is a service policy
  #checkov:skip=CKV_AWS_356: Needs to access multiple resources
  #checkov:skip=CKV_AWS_109: Needs to access multiple resources

  statement {
    sid       = "CreateAuthor"
    effect    = "Allow"
    actions   = ["quicksight:CreateUser"]
    resources = ["arn:aws:quicksight::${var.account_ids["analytical-platform-data-production"]}:user/$${aws:userid}"]
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
  name   = "alpha-quicksight-author-access"
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

resource "aws_iam_policy" "comprehend_integration" {
  name        = "analytical-platform-comprehend-integration"
  description = "Permissions needed to use Comprehend APIs and pass batch processing role."
  policy      = data.aws_iam_policy_document.comprehend_integration.json
}

##################################################
# Comprehend Batch Processing Role
##################################################

#trivy:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "comprehend_batch_processing_assume_role" {
  #checkov:skip=CKV_AWS_111: This is a service policy
  #checkov:skip=CKV_AWS_356: Needs to access multiple resources
  #checkov:skip=CKV_AWS_109: Needs to access multiple resources
  statement {
    sid     = "AllowComprehendAssumeRoleForBatchProcessing"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["comprehend.amazonaws.com"]
    }
    # Add security constraints
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:comprehend:*:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_iam_role" "comprehend_batch_processing" {
  name               = "comprehend-batch-processing-role"
  description        = "Role for AWS Comprehend service to perform batch processing tasks."
  assume_role_policy = data.aws_iam_policy_document.comprehend_batch_processing_assume_role.json
}

#trivy:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "comprehend_batch_processing_s3_access" {
  #checkov:skip=CKV_AWS_111: This is a service policy
  #checkov:skip=CKV_AWS_356: Needs to access multiple resources
  #checkov:skip=CKV_AWS_109: Needs to access multiple resources
  statement {
    sid    = "ComprehendBatchProcessingS3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::alpha-*",
      "arn:aws:s3:::mojap-*",
      "arn:aws:s3:::alpha-*/*",
      "arn:aws:s3:::mojap-*/*",
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

resource "aws_iam_policy" "comprehend_batch_processing_s3_access" {
  name        = "comprehend-batch-processing-s3-access"
  description = "S3 access policy for Comprehend batch processing."
  policy      = data.aws_iam_policy_document.comprehend_batch_processing_s3_access.json
}

resource "aws_iam_role_policy_attachment" "comprehend_batch_processing_s3_access" {
  role       = aws_iam_role.comprehend_batch_processing.name
  policy_arn = aws_iam_policy.comprehend_batch_processing_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "comprehend_batch_processing" {
  role       = aws_iam_role.comprehend_batch_processing.name
  policy_arn = aws_iam_policy.comprehend_integration.arn
}
