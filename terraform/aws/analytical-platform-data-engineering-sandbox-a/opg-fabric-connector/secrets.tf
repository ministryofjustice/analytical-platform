resource "aws_secretsmanager_secret" "fabric_connector_tenant" {
  name        = "opg-fabric-connector/tentant-id"
  description = "Tenant ID for OPG fabric application"
}

resource "aws_secretsmanager_secret_version" "fabric_connector_tenant_value" {
  secret_id     = aws_secretsmanager_secret.fabric_connector_tenant.id
  secret_string = var.default_tenant_value
  lifecycle {
    ignore_changes = [secret_string, secret_binary]
  }
}

resource "aws_secretsmanager_secret" "fabric_connector_object" {
  name        = "opg-fabric-connector/object-id"
  description = "Object ID for OPG fabric application"
}

resource "aws_secretsmanager_secret_version" "fabric_connector_object_value" {
  secret_id     = aws_secretsmanager_secret.fabric_connector_object.id
  secret_string = var.default_object_value
  lifecycle {
    ignore_changes = [secret_string, secret_binary]
  }
}
