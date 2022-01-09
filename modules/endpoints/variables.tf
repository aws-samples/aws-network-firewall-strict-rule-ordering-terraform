# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- endpoints/variables.tf ---

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "service_name" {
  type        = string
  description = "Endpoint service name - from the information indicated in locals.tf."
}

variable "endpoint_type" {
  type        = string
  description = "Endpoint type - from the information indicated in locals.tf."
}

variable "security_group" {
  type        = list(string)
  description = "Security Group ID to use in the endpoints created."
}

variable "private_subnets" {
  type        = list(any)
  description = "List of private subnet(s) created - to place the VPC endpoints"
}