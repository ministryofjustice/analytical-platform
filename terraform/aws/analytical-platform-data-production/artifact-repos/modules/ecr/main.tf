resource "aws_ecr_repository" "this" {
  #ts:skip=AWS.AER.DP.MEDIUM.0026 ECR is shared between all environments
  name                 = var.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "this" {
  policy     = data.aws_iam_policy_document.this.json
  repository = aws_ecr_repository.this.name
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
    principals {
      type        = "AWS"
      identifiers = var.pull_arns
    }
  }
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken"
    ]
    principals {
      type        = "AWS"
      identifiers = var.push_arns
    }
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_any_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_any_image_count
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}
