// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- vpc/main.tf ---

# List of AZs available in the AWS Region
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC and Internet Gateway
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-nf-${var.identifier}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-nf-${var.identifier}"
  }
}

# SUBNETS
# Public Subnets
resource "aws_subnet" "vpc_public_subnets" {
  count                   = var.number_azs
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public-subnet-${var.identifier}-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "vpc_private_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${var.identifier}-${count.index + 1}"
  }
}

# Inspection Subnets
resource "aws_subnet" "vpc_inspection_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.inspection_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "inspection-subnet-${var.identifier}-${count.index + 1}"
  }
}

# NAT GATEWAY(s) & EIP
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

# ROUTE TABLES
# Public Route Table
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

resource "aws_route" "public_to_inspection_route" {
  count                  = var.number_azs
  route_table_id         = aws_route_table.vpc_public_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = var.anfw_endpoints[count.index]
}

# Private Route Table
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

resource "aws_route" "natgw_route" {
  count                  = var.number_azs
  route_table_id         = aws_route_table.vpc_private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw[count.index].id
}

# Inspection Route Table
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

resource "aws_route" "igw_route" {
  count                  = var.number_azs
  route_table_id         = aws_route_table.vpc_inspection_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
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

resource "aws_route" "igw_to_inspection_route" {
  count                  = var.number_azs
  route_table_id         = aws_route_table.vpc_igw_rt.id
  destination_cidr_block = var.public_cidrs[count.index]
  vpc_endpoint_id        = var.anfw_endpoints[count.index]
}

# SECURITY GROUPS
resource "aws_security_group" "vpc_sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.vpc.id
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-group-${var.identifier}-${each.value.name}"
  }
}

# VPC FLOW LOGS
# VPC Flow Log Resource
resource "aws_flow_log" "vpc_flowlog" {
  iam_role_arn    = aws_iam_role.vpc_flowlogs_role.arn
  log_destination = aws_cloudwatch_log_group.flowlogs_lg.arn
  traffic_type    = var.vpcflowlog_type
  vpc_id          = aws_vpc.vpc.id
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "flowlogs_lg" {
  name = "lg-vpc-flowlogs-${var.identifier}"
}

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
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "vpc_flowlogs_role_policy" {
  name   = "vpc-flowlog-role-policy-${var.identifier}"
  role   = aws_iam_role.vpc_flowlogs_role.id
  policy = data.aws_iam_policy_document.policy_rolepolicy_document.json
}
