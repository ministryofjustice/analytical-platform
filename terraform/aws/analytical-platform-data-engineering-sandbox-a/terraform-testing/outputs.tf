output "parameter_store_value" {
  value = nonsensitive(data.aws_ssm_parameter.test.value)
}
