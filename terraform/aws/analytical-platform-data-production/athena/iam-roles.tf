resource "aws_iam_role" "athena_spark_execution_role" {
  name = "AthenaSparkExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "athena.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "athena_spark_s3_access" {
  role       = aws_iam_role.athena_spark_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

resource "aws_iam_role_policy" "inline_policy" {
  role   = aws_iam_role.athena_spark_execution_role.name
  name   = "athena-spark-dump-bucket-access"
  policy = data.aws_iam_policy_document.athena_spark.json
}
