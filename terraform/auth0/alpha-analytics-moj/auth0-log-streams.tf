resource "auth0_log_stream" "aws_eventbridge_data_platform_apps_and_tools_production" {
  name   = "data-platform-apps-and-tools-production"
  type   = "eventbridge"
  status = "active"

  sink {
    aws_account_id = "096705367497"
    aws_region     = "eu-west-2"
  }
}

resource "auth0_log_stream" "aws_eventbridge_analytical_platform_development" {
  name   = "analytical-platform-development"
  type   = "eventbridge"
  status = "active"

  sink {
    aws_account_id = "525294151996"
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
