data "pagerduty_vendor" "cloudwatch" {
  name = "Amazon CloudWatch"
}

# Commenting out because this is currently broken - https://github.com/PagerDuty/terraform-provider-pagerduty/issues/675
# data "pagerduty_vendor" "github" {
#   name = "GitHub"
# }

data "pagerduty_vendor" "airflow" {
  name = "Airflow Integration"
}
