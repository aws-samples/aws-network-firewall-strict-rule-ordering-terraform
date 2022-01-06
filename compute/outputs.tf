// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- compute/outputs.tf ---

# List of instances that are created
output "instances_created" {
  value = { for i in aws_instance.ec2_instance : i.tags.Name => i.arn }
}