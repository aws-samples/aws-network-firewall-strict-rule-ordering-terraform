# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- vpc/outputs.tf ---

output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "VPC ID"
}

output "inspection_subnets" {
  value       = aws_subnet.vpc_inspection_subnets.*.id
  description = "List of inspection subnet(s) created."
}

output "private_subnets" {
  value       = aws_subnet.vpc_private_subnets.*.id
  description = "List of private subnet(s) created."
}

output "security_group_endpoints" {
  value       = [aws_security_group.security_groups["endpoints"].id]
  description = "List of IDs of the Security Groups used by VPC endpoints."
}

output "security_group_instances" {
  value       = [aws_security_group.security_groups["instance"].id]
  description = "List of IDs of the Security Groups used by EC2 instances."
}