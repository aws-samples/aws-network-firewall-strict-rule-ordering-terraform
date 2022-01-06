// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- vpc/variables.tf ---

# The number of AZs to use - min = 1 / max = 3
variable "number_azs" {
  description = "Number of Availability Zones to create resources in the VPC."
}

# VPC CIDR
variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC"
}

# CIDR blocks to use in the public subnet(s)
variable "public_cidrs" {}

# CIDR blocks to use in the inspection subnet(s)
variable "inspection_cidrs" {}

# CIDR blocks to use in the private subnet(s)
variable "private_cidrs" {}

# Security Groups information
variable "security_groups" {}

# AWS Network Firewall endpoint(s) ID
variable "anfw_endpoints" {}

# VPC Flow log type
variable "vpcflowlog_type" {}

# Project identifier
variable "identifier" {}