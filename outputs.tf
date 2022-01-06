// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

# List of instances created
output "instances_created" {
  value = module.compute.instances_created
}

# ARN of the AWS Network Firewall created
output "anfw_arn" {
  value = module.firewall.anfw_name
}

# List of VPC endpoints created
output "vpc_endpoints" {
  value = module.endpoints
} 