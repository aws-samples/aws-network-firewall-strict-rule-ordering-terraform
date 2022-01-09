# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

# List of EC2 instances created in this environment
output "instances_created" {
  value       = module.compute.instances_created
  description = "List of EC2 instances created in this environment."
}

# ARN of the AWS Network Firewall created
output "anfw_arn" {
  value       = module.firewall.anfw_name
  description = "ARN of the AWS Network Firewall resource created."
}

# List of VPC endpoints created
output "vpc_endpoints" {
  value       = module.endpoints
  description = "List of VPC endpoints created."
}

# ARN of the KMS key created
output "kms_key_arn" {
  value       = module.kms.kms_arn
  description = "ARN of the KMS key created."
}