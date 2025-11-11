#trivy:ignore:avd-aws-0132:Replicating existing bucket that does not encrypt data with a customer managed key
#trivy:ignore:avd-aws-0090:Bucket versioning is not preferred for this bucket for now as data is processed on-demand
#trivy:ignore:avd-aws-0089:Bucket logging is not required
module "mojap_transcribe_spike" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.8.2"

  bucket              = "mojap-transcribe-spike"
  force_destroy       = false
  object_lock_enabled = false
  versioning = {
    status     = "Suspended"
    mfa_delete = false
  }
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = false

      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_policy = true
  policy        = data.aws_iam_policy_document.mojap_transcribe_spike.json

  tags = var.tags
}

data "aws_iam_policy_document" "mojap_transcribe_spike" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      "arn:aws:s3:::mojap-transcribe-spike/*",
      "arn:aws:s3:::mojap-transcribe-spike"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
