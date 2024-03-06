data "aws_iam_policy_document" "assume_role_transfer_user" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "transfer_user_jacobwoffenden" {
  name               = "transfer-user-jacobwoffenden"
  assume_role_policy = data.aws_iam_policy_document.assume_role_transfer_user.json
}

data "aws_iam_policy_document" "transfer_user_jacobwoffenden" {
  statement {
    sid       = "AllowS3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${module.landing_bucket.s3_bucket_id}"]
  }
  statement {
    sid       = "AllowS3ObjectActions"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${module.landing_bucket.s3_bucket_id}/*"]
  }
}

resource "aws_iam_role_policy" "transfer_user" {
  name   = "transfer-user-jacobwoffenden"
  role   = aws_iam_role.transfer_user_jacobwoffenden.id
  policy = data.aws_iam_policy_document.transfer_user_jacobwoffenden.json
}

resource "aws_transfer_user" "user" {
  server_id = aws_transfer_server.this.id
  user_name = "jacobwoffenden"
  role      = aws_iam_role.transfer_user_jacobwoffenden.arn

  # TODO: This should be refactored, in particular the target
  # home_directory_type = "LOGICAL"
  # home_directory_mappings {
  #   entry  = "/"
  #   target = "/${module.landing_bucket.s3_bucket_id}/$${Transfer:UserName}"
  # }

  # TEST
  home_directory = "/${module.landing_bucket.s3_bucket_id}/jacobwoffenden"

  # TODO: Tagging
}

resource "aws_transfer_ssh_key" "ssh_key" {
  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.user.user_name
  body      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+3qaLVtn6Pd+DasWHhIOBoXEEhF9GZAG+DYfJBeySS Ministry of Justice"
}

