module "antony_vpc_sandbox_kms" {
    source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms?ref=fe1beca2118c0cb528526e022a53381535bb93cd"

    description = "KMS key for antony-vpc-sandbox"
    enable_key_rotation = true

    key_statements = [
        {
            sid = "AllowLambdaServiceAccess"
            effect = "Allow"
            actions = [
                "kms:Decrypt*",
                "kms:Encrypt*",
                "kms:Describe*",
                "kms:GenerateDataKey*",
            ]
            resources = ["*"]
            principals = [
                {
                    type = "Service"
                    identifiers = ["lambda.amazonaws.com"]
                },
            ]
        },
    ]
    tags = var.tags
    deletion_window_in_days = 7
}
