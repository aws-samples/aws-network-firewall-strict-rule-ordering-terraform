# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- firewall/outputs.tf ---

output "anfw_endpoints" {
  value       = [for i in aws_networkfirewall_firewall.anfw.firewall_status[0].sync_states : i.attachment[0].endpoint_id]
  description = "Network Firewall endpoint ID(s) created. Passed as variable in the VPC module to add the route(s) in the correspoinding route table(s)"
}

output "anfw_name" {
  value       = aws_networkfirewall_firewall.anfw.id
  description = "AWS Network Firewall ARN."
}