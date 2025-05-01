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
    ssh_pub_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5YrYI+G5qeBysi0RAdt71ugWWYv0O+22f5pKfTTNeSqGVnUHTfyg5hTiuH7Ipg+tSBnLwy/U2bHl3rXqODce/MJ1TO7CnRjTp/8hrMQqLEXPyEmybLDHOvouSofuXh2qdIEiAlPwcZYMtiol8KbEfHTfmKBRb7IykelVpmV0kcAaVLDRaXyriXoae/xnrE65tKyd2a7B3l1olzJk4D1iTR+70YkRMuvQ4la/yq2pGWmElrSDsHOcXa3zDBXknrlqWCIu2jKcMn4TfoOo6Md7oaEtvtikwd6TSxIfXukeJdEsIy1iF8n6iHl/YRqzlURQZph5QsT7ZxGqBUgnLrguF7StSnjVmjwHf05WmW93V23RaOczzKHCFu3C0ADWU9mP40Xlwqhpvu2yCTxMvMQgyuWKNefq1CkBAMxJh17gSaPuq+dsc5EEiIKKC4pus9XJqsyPSsfTdxVzENjlD9ovIvn/9j2Q3e09eFct7Utk4uN2Vf7jrzRhSWAJ5f91YnI4kPOOmfdohe0uGJJY5kAHzDXXVLyy+IJkOHOF+hdRVNQZ/seHBDX/Ar1Akv6nRo0HZ6pCMfGLaEWXbcls5hmpCVIXYD/McoGMVZQf9Rb5xQ53BMtoy5yIgqfpPu+woqRxlGxVqlo2hv13Z9RczGS5qg1ZBy81E/Y1N4CxFtlx9gw== tamsin.forbes@L1244"
  }
}
