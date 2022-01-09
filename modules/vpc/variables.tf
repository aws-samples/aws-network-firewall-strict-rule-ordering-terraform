# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- vpc/variables.tf ---

variable "number_azs" {
  type        = number
  description = "Number of Availability Zones to create resources in the VPC."
}

variable "vpc_cidr" {
  type        = string
  description = "IPv4 CIDR block for the VPC"
}

variable "public_cidrs" {
  type        = list(any)
  description = "CIDR blocks to use in the public subnet(s)."
}

variable "inspection_cidrs" {
  type        = list(any)
  description = "CIDR blocks to use in the inspection subnet(s)."
}

variable "private_cidrs" {
  type        = list(any)
  description = "CIDR blocks to use in the private subnet(s)."
}

variable "anfw_endpoints" {
  type        = list(any)
  description = "AWS Network Firewall endpoint ID(s)"
}

variable "vpcflowlog_type" {
  type        = string
  description = "VPC flow log type."
}

variable "kms_key" {
  type        = string
  description = "KMS Key to use in the VPC Flow logs encryption."
}

variable "security_groups" {
  type        = any
  description = "Security Groups information."
}

variable "identifier" {
  type        = string
  description = "Project identifier."
}