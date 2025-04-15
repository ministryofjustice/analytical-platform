locals {
  name = "development-powerbi-test-vpc"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  powerbi_test_role = "development-powerbi-test"

  powerbi_test_ec2 = {
    instance_name       = "development-powerbi-test"
    most_recent         = true
    name                = ["Windows_Server-2025-English-Full-Base-*"]
    virtualization_type = "hvm"
    owner_account       = "801119661308" # amazon
    instance_type       = "t3a.xlarge"   # 4vCPU, 16G RAM
    ssh_pub_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDe4WCVutEI/uMSwGOZOMAen9X2e/nDMXmroGFSNpOx9ynXzojOX6kmqqUTsIzsrmsy+1iXQaGoj2FUbeK08GhUcB0Vjqr3iVZehkrapzRbuWK0DEaHtqeE9Ic0x4hJaYYK5y/1+7Mm2ZFG5WB6eWnk9U7J/TQHB0QkMnxYV7gp9uS3LtMeiejul7uqqOuzodtSFMW1byRqRZMmebnUXT2JGki+61w/17IxRcG7duOb0JmRthM+rqEQnYT3++SMCs5WQD46JrBOmsQdSNggwQeKkkh5z3zjkQpqXdYuGQOdT6t2bBoqaxhx5ZGo2Yjqk1+eQNAnVGT+PatlJxam5Vu7O0zDm1WWNA5XYTUZ4PFVF2V3h0UmR0MBtiQN2uDC/x1aMaqD9GENYLp8OauQ3viCmBUfJqq3fg5T8U+IkhUTD/Fd1OSHNW+dlfV0rZK6XSuW/VvRYi1VWhOuVK3HGrf4j9TfcRFAAN9ZWjvjtqcim2ipAaHUWN+hWJLV2FsUkU6M9iWSf7Nb9Ed289/HMbDdfoC3CrogU0IoVW4fK5HyzIiUGDtAH/LvTjYuU9GKHbnd7KAyAXfhLWMm4kjFWtzMc7/xszKuoAeLQYJnJ6iN+C6x1jchb2GwTsNbiLGxRlFRkUTQkQUX20Apy66QcQ2maImd4l00Fh8rIDBwupzjsQ== vscode@c1ac7c3d2c32"
  }
}
