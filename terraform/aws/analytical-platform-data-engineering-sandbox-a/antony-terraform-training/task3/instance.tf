resource "aws_instance" "ec2_instance" {
  instance_type = "t3.micro"
  metadata_options {
    http_tokens = "required"
  }
  ami           = data.aws_ssm_parameter.ssm_parameter_task3.value
  user_data = <<-EOF
                #!/bin/bash
                dnf install -y nginx
                echo '<h1>Welcome to Antony's Terraform Training Task 3</h1>' > /usr/share/nginx/html/index.html
                systemctl enable nginx
                systemctl start nginx
                mkfs -t xfs /dev/xvdf
                mkdir -p /data
                mount /dev/xvdf /data
                echo '/dev/xvdf /data xfs defaults,nofail 0 2' >> /etc/fstab
                EOF
}

resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = "us-east-1a"
  size              = 10
  tags              = var.tags
}

resource "aws_volume_attachment" "ebs_volume_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.ec2_instance.id
}