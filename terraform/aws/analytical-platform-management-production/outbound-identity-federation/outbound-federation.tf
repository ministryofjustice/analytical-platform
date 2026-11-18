# Enables AWS outbound identity federation for the whole account. This is a
# singleton, account-wide feature flag - treat it as independent infrastructure,
# not owned by any one consumer (e.g. octo-sts-local-terraform-runs).
resource "aws_iam_outbound_web_identity_federation" "this" {}
