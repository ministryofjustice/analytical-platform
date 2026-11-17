# Import existing DMS VPC IAM role
import {
  to = aws_iam_role.dms
  id = "dms-vpc-role"
}

# Import existing DMS CloudWatch IAM role
import {
  to = aws_iam_role.dms_cloudwatch
  id = "dms-cloudwatch-logs-role"
}

# Import existing DMS CloudWatch policy attachment
import {
  to = aws_iam_role_policy_attachment.dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole
  id = "dms-cloudwatch-logs-role/arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

# Import existing DMS VPC policy attachment
import {
  to = aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole
  id = "dms-vpc-role/arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

# IAM Role for DMS VPC Access
# Shared across all pipelines as all in one account
resource "aws_iam_role" "dms" {
  # This has to be a specific name for some reason see https://repost.aws/questions/QU61eADUU7SnO-t7MmhxgfPA/dms-service-roles
  name = "dms-vpc-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "dms.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    { Name = "dms-vpc-role" },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms.name

  # It takes some time for these attachments to work, and creating the aws_dms_replication_subnet_group fails if this attachment hasn't completed.
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

# IAM Role for DMS Cloudwatch Access
# Shared across all pipelines as all in one account
resource "aws_iam_role" "dms_cloudwatch" {
  # This has to be a specific name for some reason
  name = "dms-cloudwatch-logs-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "dms.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  description = "Allows Database Migration Service to call AWS services on your behalf."

  tags = merge(
    { Name = "dms-cloudwatch-logs-role" },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms_cloudwatch.name
}
