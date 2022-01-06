// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- endpoints/main.tf ---

# VPC Endpoints - it iterates from the list of services names passed as variables
# As the endpoints are created in the same VPC they are accessed, Private DNS is enabled
resource "aws_vpc_endpoint" "endpoint" {
  vpc_id              = var.vpc_id
  service_name        = var.service_name
  vpc_endpoint_type   = var.endpoint_type
  security_group_ids  = var.security_groups
  private_dns_enabled = true
}

# VPC Endpoint subnet association. 
# This resource is used to add a explicit association between the endpoint and the subnet (in case the number of AZs is changed two a lower number than what it is deployed)
resource "aws_vpc_endpoint_subnet_association" "endpoint_subnet_assoc" {
  count = length(var.private_subnets)
  vpc_endpoint_id = aws_vpc_endpoint.endpoint.id
  subnet_id = var.private_subnets[count.index]
}

