# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/locals.tf ---

locals {
  # Security Groups (SGs) used by the EC2 instances ("instance") and VPC endpoints ("endpoints"). 
  # Feel free to change the instance SG (remember to change the firewall rules accordingly). The SG of the endpoints needs to allow HTTPS traffic for the SSM connection to work. 
  security_groups = {
    instance = {
      name        = "instance_sg"
      description = "Security Group used in the instances"
      ingress = {
        any = {
          description = "Any traffic"
          from        = 0
          to          = 0
          protocol    = "-1"
          cidr_blocks = [var.cidr_block]
        }
      }
      egress = {
        icmp = {
          description = "ICMP traffic"
          from        = -1
          to          = -1
          protocol    = "icmp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        http = {
          description = "HTTP traffic"
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        https = {
          description = "HTTPS traffic"
          from        = 443
          to          = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    endpoints = {
      name        = "endpoints_sg"
      description = "Security Group for SSM connection"
      ingress = {
        https = {
          description = "HTTPS access from the VPC"
          from        = 443
          to          = 443
          protocol    = "tcp"
          cidr_blocks = [var.cidr_block]
        }
      }
      egress = {
        https = {
          description = "Any traffic"
          from        = 0
          to          = 0
          protocol    = "-1"
          cidr_blocks = [var.cidr_block]
        }
      }
    }
  }

  # VPC Endpoints service names - used when creating the endpoints. If you want to add more VPC endpoints (Amazon S3, for example), include that information here.
  endpoint_service_names = {
    ssm = {
      name = "com.amazonaws.eu-west-1.ssm"
      type = "Interface"
    }
    ssmmessages = {
      name = "com.amazonaws.eu-west-1.ssmmessages"
      type = "Interface"
    }
    ec2messages = {
      name = "com.amazonaws.eu-west-1.ec2messages"
      type = "Interface"
    }
  }
}

