// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- vpc/outputs.tf ---

# VPC ID
output "vpc_id" {
  value = aws_vpc.vpc.id
}

# Inspection subnet(s) created
output "inspection_subnets" {
  value = aws_subnet.vpc_inspection_subnets.*.id
}

# Private subnet(s) created
output "private_subnets" {
  value = aws_subnet.vpc_private_subnets.*.id
}

# Security group ID to use in the VPC endpoints
output "security_group_endpoint" {
  value = [aws_security_group.vpc_sg["endpoints"].id]
}

# Security group ID to use in the EC2 instance(s)
output "security_group_instance" {
  value = [aws_security_group.vpc_sg["instance"].id]
}