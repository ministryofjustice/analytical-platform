# Account ids
data "aws_caller_identity" "destination" {
  provider = aws.destination
}

data "aws_caller_identity" "source" {
  provider = aws.source
}

# Regions

data "aws_region" "destination" {
  provider = aws.destination
}

data "aws_region" "source" {
  provider = aws.source
}
