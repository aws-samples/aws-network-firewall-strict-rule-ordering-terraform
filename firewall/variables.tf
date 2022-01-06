// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- firewall/variables.tf ---

# VPC ID
variable "vpc_id" {}

# List of inspection subnet(s) created - to place the VPC endpoints
variable "inspection_subnets" {}

# Project identifier
variable "identifier" {}