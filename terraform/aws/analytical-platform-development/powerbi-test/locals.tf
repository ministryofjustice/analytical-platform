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
    ssh_pub_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDUblimrIplKnxcf0uX1rRTEa7I83C1iBQsrohjT8CFWD+DmYVXPceQqe2YK06m3f3zMeAYaWBupUd6BoqgiZBLl+hUF/qm/ppeRjcjwvQLy4VyqIbTLiSPRgiqT84noOvphIQOkteYebyRpwv3evRzCWWImBDHSkwno42dqU3VcbI7FjQh+p5Lx0ZgUGiEMidwb18BGV+aO2AtYoLFRxpEpuSh1cm5wyugXvc/T9XX3TKmpPf1dQYvi4LSbmhpfeCYrlMlE80upVkl176GsCNM1gsY9DjcJSdSZGTD+OhfGqCT1Jgs9c/lq7Vx6HqXOxIcP5z5BASRWGPK8O6OsJDoW+EC95Lh+cq2zUYaZXCwbgfAylE9oUEwdgooe6ADrBn9zZLa7HxIlj+AjN4zKzhFczvlcbawyZVp5iiKuncJcrDmHkre4CqO5WSf1OR+LRPWwdZqVBjoKo1+CwsMplm8imOts5/m0TSEIRZMVdN8TSbsnflIqZ5+UNH9lt9xwo0= gary.henderson@MJ004516"
  }
}
