resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2_iam_role"
  tags = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_iam_role_policy_attachment" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_iam_instance_profile" {
  name = "ec2_iam_instance_profile"
  role = aws_iam_role.ec2_iam_role.name
  tags = var.tags
}
    