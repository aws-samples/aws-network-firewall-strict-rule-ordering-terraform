// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- firewall/main.tf ---

# AWS Network Firewall
resource "aws_networkfirewall_firewall" "anfw" {
  name                = "ANFW-${var.identifier}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.anfw_policy.arn
  vpc_id              = var.vpc_id

  dynamic "subnet_mapping" {
    for_each = var.inspection_subnets

    content {
      subnet_id = subnet_mapping.value
    }
  }
}

# LOGGING
# Logging Configuration
resource "aws_networkfirewall_logging_configuration" "anfw_logs" {
  firewall_arn = aws_networkfirewall_firewall.anfw.arn
  logging_configuration {

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.anfwlogs_lg_flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.anfwlogs_lg_alert.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

# CloudWatch Log Group (FLOW)
resource "aws_cloudwatch_log_group" "anfwlogs_lg_flow" {
  name = "lg-anfwlogs-flow-${var.identifier}"
}

# CloudWatch Log Group (ALERT)
resource "aws_cloudwatch_log_group" "anfwlogs_lg_alert" {
  name = "lg-anfwlogs-alert-${var.identifier}"
}
