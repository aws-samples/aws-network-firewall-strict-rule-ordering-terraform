// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- endpoints/outputs.tf ---

# VPC endpoints created
output "vpc_endpoints" {
  value = aws_vpc_endpoint.endpoint.id
} 