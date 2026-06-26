# -----------------------------------------------------------------------------
# Redshift Serverless Namespace
# -----------------------------------------------------------------------------
resource "aws_redshiftserverless_namespace" "this" {
  namespace_name = "${var.project_name}-${var.environment}"

  admin_username        = "admin"
  manage_admin_password = true

  iam_roles = [
    aws_iam_role.redshift.arn
  ]

  kms_key_id = var.kms_key_arn

  log_exports = ["userlog", "connectionlog", "useractivitylog"]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}"
  })
}

# -----------------------------------------------------------------------------
# Redshift Serverless Workgroup
# -----------------------------------------------------------------------------
resource "aws_redshiftserverless_workgroup" "this" {
  depends_on = [aws_redshiftserverless_namespace.this]

  namespace_name = aws_redshiftserverless_namespace.this.id
  workgroup_name = aws_redshiftserverless_namespace.this.id

  # Price-performance scaling configuration
  price_performance_target {
    enabled = true
    level   = var.price_performance_level
  }

  security_group_ids = [module.redshift_sg.security_group_id]
  subnet_ids         = var.database_subnets

  enhanced_vpc_routing = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}"
  })
}
