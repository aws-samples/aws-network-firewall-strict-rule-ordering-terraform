// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# VPC Module. The subnets' CIDRs (Public, Private, and Inspection ones) are going to be generated automatically from the VPC CIDR (defined in locals.tf)
module "vpc" {
  source           = "./vpc"
  vpc_cidr         = local.vpc_cidr
  number_azs       = var.number_azs
  public_cidrs     = [for i in range(0, 6, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs    = [for i in range(1, 6, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  inspection_cidrs = [for i in range(6, 12, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  security_groups  = local.security_groups
  anfw_endpoints   = module.firewall.anfw_endpoints
  vpcflowlog_type  = var.vpcflowlog_type
  identifier       = var.project_identifier
}

# Module that creates AWS Network Firewall resource
module "firewall" {
  source             = "./firewall"
  vpc_id             = module.vpc.vpc_id
  inspection_subnets = module.vpc.inspection_subnets
  identifier         = var.project_identifier
}

# Module that creates the VPC endpoints. The endpoints to create are defined in the locals.tf file
# To allow AWS Systems Manager to access the instances withouth Internet access, please leave the 3 endpoints already configured (ssm, ssmmessages, and ec2messages)
module "endpoints" {
  for_each = local.endpoint_service_names
  source                 = "./endpoints"
  vpc_id                 = module.vpc.vpc_id
  service_name = each.value.name
  endpoint_type = each.value.type
  security_groups        = module.vpc.security_group_endpoint
  private_subnets        = module.vpc.private_subnets
}

# Compute module. It creates 1 EC2 instance (Amazon Linux 2) in each private subnet that it is created (1 per AZ created)
module "compute" {
  source                  = "./compute"
  number_azs              = var.number_azs
  private_subnets         = module.vpc.private_subnets
  instance_security_group = module.vpc.security_group_instance
  instance_type           = var.instance_type
  identifier              = var.project_identifier
}