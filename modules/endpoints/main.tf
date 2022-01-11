# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- endpoints/main.tf ---

# VPC Endpoints - it iterates from the list of services names passed as variables
# As the endpoints are created in the same VPC they are accessed, Private DNS is enabled
resource "aws_vpc_endpoint" "endpoint" {
  vpc_id              = var.vpc_id
  service_name        = var.service_name
  vpc_endpoint_type   = var.endpoint_type
  subnet_ids          = var.private_subnets
  security_group_ids  = var.security_group
  private_dns_enabled = true
}
