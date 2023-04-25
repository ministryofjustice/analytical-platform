resource "pagerduty_user" "this" {
  name  = var.name
  email = var.email

  lifecycle {
    ignore_changes = [
      job_title # Users can customise this in PagerDuty
    ]
  }
}
