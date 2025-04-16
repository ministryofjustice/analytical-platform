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
    ssh_pub_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCUyeDduoNLszf/iRbSlCDo0hnzZjnkIz2zjOFM9hL47GWKEh9mtbU6S6H/Fm7OldGHNEFGrKRJM5Fj51NN/+HkEU9p1nNW7GRQQjlyzMIa8iWNTX5/yn8rK8ThSi3hBL6HpCCVsMAjCg4PhYgGRoxURGCVKqaKOkZGsyNazJXxCXixiwgJsqy/Zu1Y5vE28Jw7nbMVEhi44icNfF83mEJ9JvewL0YT/VYQitKFqjNNYTvJKXZmEwzfiGf966VPHEjKJ0PaXBFpr6FYRaWs6JWpKSKk9nUi7O5X54Dpzj50zwxpEMdrWemrY7buhXE6gQGKneh8bXxzZtKUAoL5VdSH"
  }
}
