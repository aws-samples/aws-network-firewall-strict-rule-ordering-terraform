// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- endpoints/variables.tf ---

# VPC ID
variable "vpc_id" {}

# Endpoint service names and type - from the information indicated in locals.tf
variable "service_name" {}

variable "endpoint_type" {}

# Security Group (ID) to use in the endpoints created
variable "security_groups" {}

# List of private subnet(s) created - to place the VPC endpoints
variable "private_subnets" {}