# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- compute/main.tf ---

# Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}

# IAM ROLE - SSM access
# IAM instance profile
resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "ec2_ssm_instance_profile_${var.identifier}"
  role = aws_iam_role.role_ec2_ssm.id
}

# IAM role
data "aws_iam_policy_document" "policy_document" {
  statement {
    sid     = "1"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

  }
}

resource "aws_iam_role" "role_ec2_ssm" {
  name               = "ec2_ssm_role_${var.identifier}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.policy_document.json
}

# Policy Attachments to Role
resource "aws_iam_policy_attachment" "ssm_iam_role_polcy_attachment" {
  name       = "ssm_iam_role_polcy_attachment_${var.identifier}"
  roles      = [aws_iam_role.role_ec2_ssm.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "ssm_iam_service_role_attachment" {
  name       = "ssm_iam_service_role_attachment_${var.identifier}"
  roles      = [aws_iam_role.role_ec2_ssm.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# EC2 INSTACE(s) - 1 per Availability Zone
resource "aws_instance" "ec2_instance" {
  count                       = var.number_azs
  ami                         = data.aws_ami.amazon_linux.id
  associate_public_ip_address = false
  instance_type               = var.instance_type
  vpc_security_group_ids      = var.security_group
  subnet_id                   = var.private_subnets[count.index]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_instance_profile.id

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "instance-${count.index + 1}"
  }
}


