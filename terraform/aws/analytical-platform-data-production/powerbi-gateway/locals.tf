locals {
  name = "data-production-powerbi-vpc"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  powerbi_gateway_role = "data-production-powerbi"

  powerbi_gateway_ec2 = {
    instance_name       = "data-production-powerbi"
    most_recent         = true
    name                = ["Windows_Server-2022-English-Full-Base-*"]
    virtualization_type = "hvm"
    owner_account       = "801119661308" # amazon
    instance_type       = "t3a.xlarge"   # 4vCPU, 16G RAM
    ssh_pub_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/GZpeWlEowP4P8/+uV27S/zXmFx7ZjrmsRcwa3Q8Kcb7uGACtJU3vvPjOCWW+RSmkaZmwQt4wjssMeXI2iVfSTqhOqoM8J657KhwxKnABfF+h0I9cDyvC1JISiWNVfPue9tCitmRyNtPB1Jq9aX9W0kiYWr35uLs05pzZBP2+IQJmtIWaWfQkca/7tgKIN3T52koWqj0vQdY9Tk9rDtrRuWao9fqrjJCe0f75/FAPBrrtgoJ7WjJRu4BOiBQzkkGHAWoRnlwDQzAHUEMDuOnTJjbu0AaBg3VoKhcBpehA9AAp+6rwmyphyrCrt9hTzyxw6As4F0Q+UQH1P6S4jt3GVh0LvOzLmIZeKf8AnbtkeoO3KK4xVfA8GwyuFTRKaR27Ipp3R2sfDe1US7OX6ha0Ftd70eWv1Fug8A+T/VviBJmFeXY/rE2yTl4gSkUkDggLBfSL7poZKZ18BDEC6RxRZBkPnxLbt5Cl9bmkORfkpducVz3MAF/L3oPYT2hQ1jnajFrKvuOsM2vJ9nFpxNlLoXI462Wr0JbsimuAKWLQoiyOoZLXX3fKqZ8n3KU8yFfbPKnHp66kLiitN46Gtine3sXWrVCwOjLftbZxeyd7SlRFDwVjSfcMole9RPjFDCbwZ0Zow18joqMeXaZo3gxH1ibPj7EAfjGrlwd64v5NVw== powerbi-gateway-aws-keypair"
  }
}
