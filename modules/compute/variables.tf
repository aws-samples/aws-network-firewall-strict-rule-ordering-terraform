# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- compute/variables.tf ---

variable "number_azs" {
  type        = number
  description = "Number of availability Zones where to spin-up EC2 instances."
}

variable "private_subnets" {
  type        = list(any)
  description = "List of private subnets created - to place the EC2 instance(s)."
}

variable "security_group" {
  type        = list(string)
  description = "Security Group IDs to use in the instance(s) created."
}

variable "instance_type" {
  type        = string
  description = "Instance type."
}

variable "identifier" {
  type        = string
  description = "Project identifier."
}
