terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
  }
  required_version = "~> 1.5"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/function.zip"
}

data "aws_iam_policy_document" "lambda_kms_key" {
  statement {
    sid     = "EnableIAMUserPermissions"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    resources = ["*"]
  }

  statement {
    sid    = "AllowLambdaFunctionUse"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda_role.arn]
    }

    resources = ["*"]
  }
}

resource "aws_kms_key" "lambda" {
  policy                  = data.aws_iam_policy_document.lambda_kms_key.json
  description             = "KMS key for ${var.lambda_name} Lambda environment variables"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_sqs_queue" "dlq" {
  name              = "${var.lambda_name}-dlq"
  kms_master_key_id = aws_kms_key.lambda.id
}

resource "aws_security_group" "lambda" {
  name_prefix = "${var.lambda_name}-"
  description = "Security group for ${var.lambda_name} Lambda"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow outbound HTTPS for AWS API calls"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_role" "lambda_role" {
  name = local.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = local.lambda_policy_name
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = local.s3_object_arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:PutSecretValue",
          "secretsmanager:GetSecretValue"
        ]
        Resource = local.secret_arn
      },

      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = local.log_group_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${local.log_group_arn}:log-stream:*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.dlq.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.lambda.arn
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTelemetryRecords",
          "xray:PutTraceSegments"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:Vpc"               = var.vpc_id
            "ec2:AuthorizedService" = "lambda.amazonaws.com"
          }
          "ForAnyValue:StringEquals" = {
            "ec2:Subnet" = var.vpc_subnet_ids
          }
        }
      }
    ]
  })
}

resource "aws_signer_signing_profile" "lambda" {
  name_prefix = var.lambda_name
  platform_id = "AWSLambda-SHA384-ECDSA"

  signature_validity_period {
    value = 365
    type  = "DAYS"
  }
}

resource "aws_lambda_code_signing_config" "this" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

# The lambda function
resource "aws_lambda_function" "this" {
  function_name = var.lambda_name

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role    = aws_iam_role.lambda_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  timeout = 60

  code_signing_config_arn        = aws_lambda_code_signing_config.this.arn
  kms_key_arn                    = aws_kms_key.lambda.arn
  reserved_concurrent_executions = var.reserved_concurrent_executions

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  environment {
    variables = {
      BUCKET_NAME             = var.bucket_name
      OBJECT_KEY              = var.object_key
      SECRET_NAME             = var.secret_name
      DELETE_AFTER_PROCESSING = tostring(var.delete_after_processing)
    }
  }
}
