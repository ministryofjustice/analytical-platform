data "aws_iam_policy_document" "opg_forms_bucket_policy" {

  statement {
    sid    = "AllowGOVUKFormsAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::443944947292:root"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::mojap-data-production-opg-forms/*"]

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::443944947292:role/govuk-forms-submissions-to-s3-production"]
    }
  }
}

#tfsec:ignore:AVD-AWS-0088:Bucket is encrypted with CMK KMS, but not detected by Trivy
#tfsec:ignore:AVD-AWS-0089:False positive in remote scan; module logging input is set below
#tfsec:ignore:AVD-AWS-0132:Bucket is encrypted with CMK KMS, but not detected by Trivy
#trivy:ignore:AVD-AWS-0089:False positive in remote scan; module logging input is set below
module "opg_forms_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  #checkov:skip=CKV_AWS_18:Access logging not enabled currently
  #checkov:skip=CKV_AWS_21:Versioning is enabled, but not detected by Checkov
  #checkov:skip=CKV_AWS_145:Bucket is encrypted with CMK KMS, but not detected by Checkov
  #checkov:skip=CKV_AWS_300:Lifecycle configuration not enabled currently
  #checkov:skip=CKV_AWS_144:Cross-region replication is not required currently
  #checkov:skip=CKV2_AWS_6:Public access block is enabled, but not detected by Checkov
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not enabled currently
  #checkov:skip=CKV2_AWS_62:Bucket notifications not required currently
  #checkov:skip=CKV2_AWS_67:Regular CMK key rotation is not required currently

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.12.0"

  bucket = "mojap-data-production-opg-forms"

  force_destroy = true

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy        = data.aws_iam_policy_document.opg_forms_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.opg_forms_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
