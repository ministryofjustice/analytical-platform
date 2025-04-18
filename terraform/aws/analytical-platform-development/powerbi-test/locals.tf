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
    # ssh_pub_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIV+8W60eCb9VP7TrL4U1PKiybEnl6NhZ3pC+UNfxtPdPKXg1/5d6yfXrnJRF/59R9kIv6h7bcjzjkuAdS5kzk1Pk/pOMpbfPbXS6uYEJ4ONgt0BCr6e07ho9io/zpw0dEuaWxcFOuqXUvEGI8s9m3F0aTNKAD6eO1U+UP1QWtyNKnacnP0c+l9Iff65j1TgRsWnYTMbGNyQ6rnygbyr7xyC+BN7jgUq81Ct5ChECeTFJ7iUne7L9fqPRBfdhgjBz0LEtWbpm6xwhX7V9wnEpGoc04qFR77zwBa5MV676GioD2C2bUMNf2CKF1QfIfxa9YsPpZygmOE/MYHficK0Vv"
    # ssh_pub_key         = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyFfvFutHgm/VT+06y+FNTyosmxJ5ejYWd6QvlDX8bT3Tyl4Nf+Xesn165yURf+fUfZCL+oe23I845LgHUuZM5NT5P6TjKW3z210urmBCeDjYLdAQq+ntO4aPYqP86cNHRLmlsXBTrql1LxBiPLPZtxdGkzSgA+njtVPlD9UFrcjSp2nJz9HPpfSH3+uY9U4EbFp2EzGxjckOq58oG8q+8cgvgTe44FKvNQreQoRAnkxSe4lJ3uy/X6j0QX3YYIwc9CxLVm6ZuscIV+1fcJxKRqHNOKhUe+88AWuTFeu+hoqA9gtm1DDX9gihdUHyH8WvWLD6WcoJjhPzGB34nCtFbwIDAQAB"
    ssh_pub_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIV+8W60eCb9VP7TrL4U1PKiybEnl6NhZ3pC+UNfxtPdPKXg1/5d6yfXrnJRF/59R9kIv6h7bcjzjkuAdS5kzk1Pk/pOMpbfPbXS6uYEJ4ONgt0BCr6e07ho9io/zpw0dEuaWxcFOuqXUvEGI8s9m3F0aTNKAD6eO1U+UP1QWtyNKnacnP0c+l9Iff65j1TgRsWnYTMbGNyQ6rnygbyr7xyC+BN7jgUq81Ct5ChECeTFJ7iUne7L9fqPRBfdhgjBz0LEtWbpm6xwhX7V9wnEpGoc04qFR77zwBa5MV676GioD2C2bUMNf2CKF1QfIfxa9YsPpZygmOE/MYHficK0Vv powerbi-test-keypair\n"
  }
}
