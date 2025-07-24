resource "aws_mwaa_environment" "airflow_dev" {
  dag_s3_path          = "dags"
  requirements_s3_path = "requirements.txt"
  execution_role_arn   = aws_iam_role.airflow_dev_execution_role.arn
  name                 = "dev"

  network_configuration {
    security_group_ids = [aws_security_group.airflow_dev.id]
    subnet_ids         = [aws_subnet.dev_private_subnet[0].id, aws_subnet.dev_private_subnet[1].id]
  }

  source_bucket_arn = aws_s3_bucket.mojap_airflow_dev.arn
}

import {
  to = aws_mwaa_environment.airflow_dev
  id = "dev"
}
