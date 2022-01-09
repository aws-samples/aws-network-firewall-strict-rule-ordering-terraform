# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

# AWS Region
variable "aws_region" {
  type        = string
  description = "AWS Region to create the environment."
  default     = "eu-west-1"
}

# Project Identifier
variable "project_identifier" {
  type        = string
  description = "Project Name, used as identifer when creating resources."
  default     = "anfw-strict-rule"
}

# Number of Availability Zones (AZs) to use. The default is 1, although 2 or more are recommended for high-availability
# Take into account that, to follow best practices, each resource (EC2 instance, VPC endpoint, Network Firewall endpoint) is going to be created in each AZ configured
# Maximum of AZs is 3, to comply with maximum number of AZs in most AWS Regions.
variable "number_azs" {
  type        = number
  description = "Number of Availability Zones to create resources in the VPC."
  default     = 1

  validation {
    condition     = var.number_azs > 0 && var.number_azs < 4
    error_message = "The number of AZs to configure has to be between 1 - 3."
  }
}

# EC2 instance type
variable "instance_type" {
  type        = string
  description = "Instance type of the instances created."
  default     = "t2.micro"
}

# VPC Flow Log configuration: Type of log / Default: ALL - Other options: ACCEPT, REJECT
variable "vpcflowlog_type" {
  type        = string
  description = "The type of traffic to log in VPC Flow Logs."
  default     = "ALL"
}