resource "auth0_log_stream" "aws_eventbridge_analytical_platform_data_production" {
  name   = "analytical-platform-data-production"
  type   = "eventbridge"
  status = "active"

  sink {
    aws_account_id = "593291632749"
    aws_region     = "eu-west-2"
  }
}

resource "auth0_log_stream" "aws_eventbridge_operations_engineering_development" {
  name   = "operations-engineering-development"
  type   = "eventbridge"
  status = "active"

  sink {
    aws_account_id = "211125434264"
    aws_region     = "eu-west-2"
  }
}
