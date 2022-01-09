# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- firewall/variables.tf ---

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "inspection_subnets" {
  type        = list(any)
  description = "List of inspection subnet(s) created - to place the Network Firewall endpoints"
}

variable "kms_key" {
  type        = string
  description = "KMS Key to use in the VPC Flow logs encryption"
}

variable "identifier" {
  type        = string
  description = "Project identifier"
}