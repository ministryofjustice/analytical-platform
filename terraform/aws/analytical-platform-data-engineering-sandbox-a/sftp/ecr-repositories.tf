/*
  This will not carry over to the proper environment.
*/
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_name                 = "analytical-platform-family-transfer-server"
  repository_image_tag_mutability = "MUTABLE"

  repository_lambda_read_access_arns = ["arn:aws:lambda:eu-west-2:684969100054:function:*"]
  create_lifecycle_policy            = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_force_delete = true
}

module "notify" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_name                 = "analytical-platform-notify"
  repository_image_tag_mutability = "MUTABLE"

  repository_lambda_read_access_arns = ["arn:aws:lambda:eu-west-2:684969100054:function:*"]
  create_lifecycle_policy            = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_force_delete = true
}

module "transfer" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_name                 = "analytical-platform-transfer"
  repository_image_tag_mutability = "MUTABLE"

  repository_lambda_read_access_arns = ["arn:aws:lambda:eu-west-2:684969100054:function:*"]
  create_lifecycle_policy            = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_force_delete = true
}
