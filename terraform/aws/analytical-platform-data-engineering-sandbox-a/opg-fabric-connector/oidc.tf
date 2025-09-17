resource "aws_iam_openid_connect_provider" "entra" {
  url = "https://sts.windows.net/<your-tenant-id>/"

  client_id_list = [
    "https://analysis.windows.net/powerbi/connector/AmazonS3",
  ]

  tags = {
    Name        = "opg-fabric-oidc-connector"
    Environment = "sandbox"
    Owner       = "opg-de"
    Project     = "OPG"
    ManagedBy   = "terraform"
  }
}