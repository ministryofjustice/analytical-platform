resource "aws_iam_role" "lambda" {
  for_each = nonsensitive(toset(keys(var.dms_config)))

  name = "${each.key}_lambda_role_test"
  assume_role_policy = jsonencode({ Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "lambda" {
  for_each = nonsensitive(toset(keys(var.dms_config)))

  name = "${each.key}_lambda_policy_test"
  role = aws_iam_role.lambda[each.key].id
  # is using a iam_policy_document data providor a possible alternative to this?
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  policy = templatefile(
    "${path.module}/lambda_policy.json",
    {
      landing_bucket   = var.dms_config[each.key].landing_bucket
      metadata_bucket  = var.dms_config[each.key].metadata_bucket
      fail_bucket      = var.dms_config[each.key].fail_bucket
      raw_hist_bucket  = var.dms_config[each.key].raw_hist_bucket
      landing_folder   = var.dms_config[each.key].landing_bucket_folder
      slack_secret_arn = var.dms_config[each.key].slack_secret_arn
    }
  )
}



module "validate_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "oracle19-validate-sandbox-test"
  description   = "Validate files arriving in mojap-land-sandbox"
  handler       = "validate.lambda_handler"
  runtime       = "python3.8"
  lambda_role   = aws_iam_role.lambda["oracle19"].arn

  create_role = false


  source_path = "lambdas/validate/validate.py"

  layers = [
    module.validate_lambda_layer.lambda_layer_arn,
  ]
}

module "validate_lambda_layer" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer   = true
  create_package = false

  layer_name          = "oracle-19-validate-layer"
  description         = "used by the validate lambda"
  compatible_runtimes = ["python3.8"]

  #source_path = "lambdas/validate/validate_layer.zip"
  local_existing_package = "lambdas/validate/validate_layer.zip"

  store_on_s3 = false
  #s3_bucket   = "my-bucket-id-with-lambda-builds"
}
