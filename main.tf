# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# ---------- AMAZON VPC ---------
# Amazon VPC - Module: https://registry.terraform.io/modules/aws-ia/vpc/aws/latest
module "vpc" {
  source  = "aws-ia/vpc/aws"
  version = "3.1.0"

  name       = "vpc-${var.identifier}"
  cidr_block = var.cidr_block
  az_count   = var.number_azs

  subnets = {
    public = {
      cidrs                     = slice(var.subnet_cidr_blocks.public, 0, var.number_azs)
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      cidrs                   = slice(var.subnet_cidr_blocks.inspection, 0, var.number_azs)
      connect_to_public_natgw = true
    }
    workload      = { cidrs = slice(var.subnet_cidr_blocks.private, 0, var.number_azs) }
    vpc_endpoints = { cidrs = slice(var.subnet_cidr_blocks.endpoints, 0, var.number_azs) }
  }

  # vpc_flow_logs = {
  #   log_destination_type = "cloud-watch-logs"
  #   retention_in_days = 7
  #   iam_role_arn = aws_iam_role.vpc_flowlogs_role.arn
  #   kms_key_id = aws_kms_key.log_key.arn
  # }
}

# We obtain the IGW ID from the VPC created
data "aws_internet_gateway" "igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [module.vpc.vpc_attributes.id]
  }
}

# IGW Route Table
resource "aws_route_table" "vpc_igw_rt" {
  vpc_id = module.vpc.vpc_attributes.id

  tags = {
    Name = "igw-rt-${var.identifier}"
  }
}

resource "aws_route_table_association" "vpc_igw_rt_assoc" {
  gateway_id     = local.igw_id
  route_table_id = aws_route_table.vpc_igw_rt.id
}

# ---------- AWS NETWORK FIREWALL ---------
# AWS Network Firewall - Module: https://registry.terraform.io/modules/aws-ia/networkfirewall/aws/latest
module "network_firewall" {
  source  = "aws-ia/networkfirewall/aws"
  version = "0.0.2"

  network_firewall_name   = "anfw-${var.identifier}"
  network_firewall_policy = aws_networkfirewall_firewall_policy.anfw_policy.arn

  vpc_id      = module.vpc.vpc_attributes.id
  number_azs  = var.number_azs
  vpc_subnets = { for k, v in module.vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }

  routing_configuration = {
    single_vpc = {
      igw_route_table               = aws_route_table.vpc_igw_rt.id
      protected_subnet_route_tables = { for k, v in module.vpc.rt_attributes_by_type_by_az.private : split("/", k)[1] => v.id if split("/", k)[0] == "workload" }
      protected_subnet_cidr_blocks  = local.private_subnet_cidrs
    }
  }
}

# Logging Configuration
resource "aws_networkfirewall_logging_configuration" "anfw_logs" {
  firewall_arn = module.network_firewall.aws_network_firewall.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.anfwlogs_lg_flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.anfwlogs_lg_alert.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

# CloudWatch Log Group (FLOW)
resource "aws_cloudwatch_log_group" "anfwlogs_lg_flow" {
  name              = "lg-anfwlogs-flow-${var.identifier}"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.log_key.arn
}

# CloudWatch Log Group (ALERT)
resource "aws_cloudwatch_log_group" "anfwlogs_lg_alert" {
  name              = "lg-anfwlogs-alert-${var.identifier}"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.log_key.arn
}

# ---------- EC2 INSTANCE ---------
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

# EC2 Instances - 1 per Availability Zone
resource "aws_instance" "ec2_instance" {
  count = var.number_azs

  ami                         = data.aws_ami.amazon_linux.id
  associate_public_ip_address = false
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.security_groups["instance"].id]
  subnet_id                   = values({ for k, v in module.vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })[count.index]
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

# Security Groups (Instances and VPC Endpoints)
resource "aws_security_group" "security_groups" {
  for_each = local.security_groups

  name        = each.value.name
  description = each.value.description
  vpc_id      = module.vpc.vpc_attributes.id

  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      description = ingress.value.description
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = each.value.egress
    content {
      description = egress.value.description
      from_port   = egress.value.from
      to_port     = egress.value.to
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name = "security-group-${var.identifier}-${each.key}"
  }
}

# ---------- VPC ENDPOINTS (SSM ACCESS) ----------
# VPC Endpoints - it iterates from the list of services names passed as variables
# As the endpoints are created in the same VPC they are accessed, Private DNS is enabled
resource "aws_vpc_endpoint" "endpoint" {
  for_each = local.endpoint_service_names

  vpc_id              = module.vpc.vpc_attributes.id
  service_name        = each.value.name
  vpc_endpoint_type   = each.value.type
  subnet_ids          = values({ for k, v in module.vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
  security_group_ids  = [aws_security_group.security_groups["endpoints"].id]
  private_dns_enabled = true
}

# --------- IAM ROLES (SSM ACCESS) ---------
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
resource "aws_iam_policy_attachment" "ssm_iam_role_policy_attachment" {
  name       = "ssm_iam_role_policy_attachment_${var.identifier}"
  roles      = [aws_iam_role.role_ec2_ssm.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --------- IAM ROLES (VPC FLOW LOGS) ---------
# IAM Role
data "aws_iam_policy_document" "policy_role_document" {
  statement {
    sid     = "1"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flowlogs_role" {
  name               = "vpc-flowlog-role-${var.identifier}"
  assume_role_policy = data.aws_iam_policy_document.policy_role_document.json
}

# IAM Role Policy
data "aws_iam_policy_document" "policy_rolepolicy_document" {
  statement {
    sid = "2"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroup",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "vpc_flowlogs_role_policy" {
  name   = "vpc-flowlog-role-policy-${var.identifier}"
  role   = aws_iam_role.vpc_flowlogs_role.id
  policy = data.aws_iam_policy_document.policy_rolepolicy_document.json
}

# ---------- KMS KEY ----------
# Data Source: AWS Caller Identity - Used to get the Account ID
data "aws_caller_identity" "current" {}

# KMS Key
resource "aws_kms_key" "log_key" {
  description             = "KMS Logs Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.policy_kms_logs_document.json

  tags = {
    Name = "kms-key-${var.identifier}"
  }
}

# KMS Policy - it allows the use of the Key by the CloudWatch log groups created in this sample
data "aws_iam_policy_document" "policy_kms_logs_document" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "Enable KMS to be used by CloudWatch Logs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}