# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.vpc.id
}

output "subnets" {
  description = "Subnet IDs (per type)."
  value = {
    inspection = aws_subnet.vpc_inspection_subnets.*.id
    public     = aws_subnet.vpc_public_subnets.*.id
    private    = aws_subnet.vpc_private_subnets.*.id
    endpoints  = aws_subnet.vpc_endpoints_subnets.*.id
  }
}

# output "route_tables" {
#   description = "Route table IDs (per type)."
#   value = {
#     igw = 
#     inspection =
#     public = 
#     private = 
#     endpoints = 
#   }
# }

output "aws_network_firewall" {
  description = "AWS Network Firewall ID."
  value       = aws_networkfirewall_firewall.anfw.id
}