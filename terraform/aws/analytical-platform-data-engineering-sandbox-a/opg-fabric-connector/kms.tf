module "opg_kms_dev" {

  # Commit hash for v3.1.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms?ref=fe1beca2118c0cb528526e022a53381535bb93cd"

  aliases                 = ["opg/opg-fabric-sandbox"]
  description             = "Used in the OPG fabric domain to encode secrets"
  enable_default_policy   = true
  deletion_window_in_days = 7

  key_statements = [
    {
      sid        = "DenyNonSecretsManagerUse"
      effect     = "Deny"
      principals = [{ type = "*", identifiers = ["*"] }]
      actions    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      resources  = ["*"]
      conditions = [
        {
          test     = "StringNotEquals"
          variable = "kms:ViaService"
          values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
    },
    {
      sid       = "AllowViaSecretsManagerForFabricRole"
      effect    = "Allow"
      actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      resources = ["*"]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/opg-fabric-s3"
        ]
      }]
      conditions = [
        { test = "StringEquals", variable = "kms:ViaService", values = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"] },
        {
          test     = "StringLike",
          variable = "kms:EncryptionContext:aws:secretsmanager:arn",
          values   = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:opg-fabric-connector/*"]
        }
      ]
    }
  ]
}

