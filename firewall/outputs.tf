// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- firewall/outputs.tf ---

# AWS Network Firewall endpoint(s) created in the inspection subnet(s)
# They are passed as variable when creating the VPC to add the route(s) in the corresponding route table(s)
output "anfw_endpoints" {
  value = [for i in aws_networkfirewall_firewall.anfw.firewall_status[0].sync_states : i.attachment[0].endpoint_id]
}

# AWS Network Firewall ARNs
output "anfw_name" {
  value = aws_networkfirewall_firewall.anfw.id
}