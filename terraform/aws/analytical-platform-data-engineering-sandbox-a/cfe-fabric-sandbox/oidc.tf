resource "aws_iam_openid_connect_provider" "cfe_fabric_connector" {
  url = "https://sts.windows.net/${local.tenant_id}/"

  client_id_list = [
    "https://analysis.windows.net/powerbi/connector/AmazonS3",
  ]

  tags = {
    Name = "cfe-fabric-oidc-connector"
  }
}
