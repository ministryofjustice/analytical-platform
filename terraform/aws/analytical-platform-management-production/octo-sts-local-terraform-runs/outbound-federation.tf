# Enables AWS outbound identity federation for this account, used to mint the
# tokens exchanged with Octo STS by scripts/terraform/local-github-token.sh
resource "aws_iam_outbound_web_identity_federation" "this" {}
