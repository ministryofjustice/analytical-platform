data "aws_iam_policy_document" "transcribe_service_access" {
  #checkov:skip=CKV_AWS_356: skip requires access to multiple resources
  statement {
    sid    = "transcribeGenericAccess"
    effect = "Allow"
    actions = [
      "transcribe:List*",
      "transcribe:Get*",
      "transcribe:Describe*",
      "transcribe:StartStreamTranscription",
      "transcribe:StartStreamTranscriptionWebSocket",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "transcribeServiceAccess"
    effect = "Allow"
    actions = [
      "transcribe:GetTranscriptionJob",
      "transcribe:GetVocabulary",
      "transcribe:CreateVocabulary",
      "transcribe:StartTranscriptionJob",
      "transcribe:DeleteTranscriptionJob",
      "transcribe:UpdateVocabulary",
      "transcribe:CreateLanguageModel",
    ]
    resources = [
      "arn:aws:transcribe:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:vocabulary/*",
      "arn:aws:transcribe:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:transcription-job/*",
      "arn:aws:transcribe:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:language-model/*"
    ]
  }
  statement {
    sid    = "AllowS3ReadWrite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:List*",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::mojap-transcribe-spike/*",
      "arn:aws:s3:::mojap-transcribe-spike",
    ]
  }
}

resource "aws_iam_policy" "transcribe_service_access" {
  name   = "transcribe-service-access"
  policy = data.aws_iam_policy_document.transcribe_service_access.json
}

resource "aws_iam_role_policy_attachment" "transcribe_service_access_attachment" {
  for_each   = toset(local.transcribe_users)
  policy_arn = aws_iam_policy.transcribe_service_access.arn
  role       = each.value
}
