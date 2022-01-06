// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- compute/variables.tf ---

# Number of AZs to use
variable "number_azs" {}

# List of private subnet(s) created - to place the EC2 instance(s)
variable "private_subnets" {}

# Security Group (ID) to use in the instance(s) created
variable "instance_security_group" {}

# Instance Type
variable "instance_type" {}

# Project identifier
variable "identifier" {}
