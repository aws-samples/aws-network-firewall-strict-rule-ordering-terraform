# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# List of AZs available in the AWS Region
data "aws_availability_zones" "available" {
  state = "available"
}

# ------------ VPC RESOURCES (without routes) ------------
# VPC and Internet Gateway
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.identifier}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-nf-${var.identifier}"
  }
}

# Default Security Group
# Ensuring that the default SG restricts all traffic (no ingress and egress rule). It is also not used in any resource
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.vpc.id
}

# Public Subnets (to place the NAT gateways)
resource "aws_subnet" "vpc_public_subnets" {
  count = var.number_azs

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr_blocks.public[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public-subnet-${var.identifier}-${count.index + 1}"
  }
}

# Private Subnets (to place the EC2 instances)
resource "aws_subnet" "vpc_private_subnets" {
  count = var.number_azs

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr_blocks.private[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${var.identifier}-${count.index + 1}"
  }
}

# Inspection Subnets (to place the Network Firewall endpoints)
resource "aws_subnet" "vpc_inspection_subnets" {
  count = var.number_azs

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr_blocks.inspection[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "inspection-subnet-${var.identifier}-${count.index + 1}"
  }
}

# Endpoint Subnets (to place the VPC endpoints)
resource "aws_subnet" "vpc_endpoints_subnets" {
  count = var.number_azs

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr_blocks.endpoints[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "endpoints-subnet-${var.identifier}-${count.index + 1}"
  }
}

# NAT Gateways & EIPs
resource "aws_eip" "eip" {
  count = var.number_azs

  vpc   = true
}

resource "aws_nat_gateway" "natgw" {
  count         = var.number_azs

  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.vpc_public_subnets[count.index].id

  tags = {
    Name = "nat-gw-${var.identifier}-${count.index + 1}"
  }
}

# Public subnet Route Tables
resource "aws_route_table" "vpc_public_rt" {
  count  = var.number_azs

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "public-rt-${var.identifier}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "vpc_public_rt_assoc" {
  count          = var.number_azs

  subnet_id      = aws_subnet.vpc_public_subnets[count.index].id
  route_table_id = aws_route_table.vpc_public_rt[count.index].id
}

# Private subnet Route Tables
resource "aws_route_table" "vpc_private_rt" {
  count  = var.number_azs

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "private-rt-${var.identifier}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "vpc_private_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.vpc_private_subnets[count.index].id
  route_table_id = aws_route_table.vpc_private_rt[count.index].id
}

# Inspection subnet Route Tables
resource "aws_route_table" "vpc_inspection_rt" {
  count  = var.number_azs

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "inspection-rt-${var.identifier}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "vpc_inspection_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.vpc_inspection_subnets[count.index].id
  route_table_id = aws_route_table.vpc_inspection_rt[count.index].id
}

# Endpoints subnet Route Table
resource "aws_route_table" "vpc_endpoints_rt" {
  count  = var.number_azs

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "endpoints-rt-${var.identifier}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "vpc_endpoint_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.vpc_endpoints_subnets[count.index].id
  route_table_id = aws_route_table.vpc_endpoints_rt[count.index].id
}

# IGW Route Table
resource "aws_route_table" "vpc_igw_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-rt-${var.identifier}"
  }
}

resource "aws_route_table_association" "vpc_igw_rt_assoc" {
  gateway_id     = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.vpc_igw_rt.id
}

# Security Groups (Instances and VPC Endpoints)
resource "aws_security_group" "security_groups" {
  for_each    = local.security_groups

  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.vpc.id

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

# VPC Flow Log Resource
resource "aws_flow_log" "vpc_flowlog" {
  iam_role_arn    = aws_iam_role.vpc_flowlogs_role.arn
  log_destination = aws_cloudwatch_log_group.flowlogs_lg.arn
  traffic_type    = var.vpcflowlog_type
  vpc_id          = aws_vpc.vpc.id
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "flowlogs_lg" {
  name              = "lg-vpc-flowlogs-${var.identifier}"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.log_key.arn
}

# ------------ AWS NETWORK FIREWALL RESOURCES ------------
# AWS Network Firewall
resource "aws_networkfirewall_firewall" "anfw" {
  name                = "ANFW-${var.identifier}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.anfw_policy.arn
  vpc_id              = aws_vpc.vpc.id

  dynamic "subnet_mapping" {
    for_each = aws_subnet.vpc_inspection_subnets.*.id

    content {
      subnet_id = subnet_mapping.value
    }
  }
}

# Logging Configuration
resource "aws_networkfirewall_logging_configuration" "anfw_logs" {
  firewall_arn = aws_networkfirewall_firewall.anfw.arn
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

# ------------ VPC ROUTES ------------
# Local variable - we get the firewall endpoints from the ANFW output
locals {
  firewall_endpoints = [for i in aws_networkfirewall_firewall.anfw.firewall_status[0].sync_states : i.attachment[0].endpoint_id]
}

# From the Internet gateway to the public subnets via the Firewall endpoints
resource "aws_route" "igw_to_public_endpoints" {
  count = var.number_azs

  route_table_id         = aws_route_table.vpc_igw_rt.id
  destination_cidr_block = var.subnet_cidr_blocks.public[count.index]
  vpc_endpoint_id        = local.firewall_endpoints[count.index]
}

# From the inspection subnets to the Internet gateway (0.0.0.0/0)
resource "aws_route" "inspection_to_igw" {
  count = var.number_azs

  route_table_id         = aws_route_table.vpc_inspection_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# From the public subnets to the Internet (0.0.0.0/0) via the Firewall endpoints
resource "aws_route" "public_to_igw_endpoints" {
  count = var.number_azs

  route_table_id         = aws_route_table.vpc_public_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoints[count.index]
}

# From the private subnets to the Internet (0.0.0.0/0) via the NAT gateway
resource "aws_route" "private_to_igw_natgw" {
  count = var.number_azs

  route_table_id         = aws_route_table.vpc_private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw[count.index].id
}

# ------------ VPC ENDPOINTS (SSM ACCESS) ------------

# VPC Endpoints - it iterates from the list of services names passed as variables
# As the endpoints are created in the same VPC they are accessed, Private DNS is enabled
resource "aws_vpc_endpoint" "endpoint" {
  for_each = local.endpoint_service_names

  vpc_id              = aws_vpc.vpc.id
  service_name        = each.value.name
  vpc_endpoint_type   = each.value.type
  subnet_ids          = aws_subnet.vpc_endpoints_subnets.*.id
  security_group_ids  = [aws_security_group.security_groups["endpoints"].id]
  private_dns_enabled = true
}

# ------------ EC2 INSTANCES ------------

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
resource "aws_iam_policy_attachment" "ssm_iam_role_policy_attachment" {
  name       = "ssm_iam_role_policy_attachment_${var.identifier}"
  roles      = [aws_iam_role.role_ec2_ssm.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 INSTACE(s) - 1 per Availability Zone
resource "aws_instance" "ec2_instance" {
  count                       = var.number_azs

  ami                         = data.aws_ami.amazon_linux.id
  associate_public_ip_address = false
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.security_groups["instance"].id]
  subnet_id                   = aws_subnet.vpc_private_subnets[count.index].id
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

# ------------ IAM ROLE - VPC FLOW LOGS ------------
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

# ------------ KMS KEY ------------
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