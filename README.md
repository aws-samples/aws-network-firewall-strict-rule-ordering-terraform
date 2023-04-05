<!-- BEGIN_TF_DOCS -->
# AWS Network Firewall - Strict Rule Ordering (Logging Example) - Terraform Sample

This repository contains terraform code to deploy a single VPC with inspection using AWS Network Firewall. Stateful rule groups use **Strict Rule Ordering**, and the end goal of this example is to show how you can log both ALLOWED and DENIED traffic in the same destination directly from Network Firewall - CloudWatch logs is used in this example.

The resources deployed and the architectural pattern they follow is purely for demonstration/testing purposes.

## Prerequisites

- An AWS account with an IAM user with the appropriate permissions
- Terraform installed

## Code Principles:

- Writing DRY (Do No Repeat Yourself) code using a modular design pattern

## Usage

- Clone the repository
- Edit the variables.tf file in the project root directory. This file contains the variables that are used to configure environment.
- Initialize Terraform using `terraform init`
- Deploy the template using `terraform apply`

**Note**: The default number of Availability Zones to use is 1, although you can change this number in the input variables to a maximum number of 3. To follow best practices, each resource - EC2 instance, NAT Gateway, SSM endpoints, and Network Firewall endpoint - will be created in each Availability Zone. **Keep this in mind** to avoid extra costs unless you are happy to deploy more resources and accept additional costs.

## Deployment

### AWS Network Firewall

The AWS Network Firewall Policy is defined in the policy.tf file in the firewall directory. The firewall policy is configured to use Strict Rule Ordering with "Alert All" and "Drop All" as default actions. 3 rules groups are configured:

- One stateless rule group denying any SSH or RDP communication.
- Two stateful rule groups: one allowing ICMP communication, and another one allowing communication with the domains "example.com" and ".amazon.com".

All the **pass** actions are duplicated with **alert** ones first. That way the alert rule generates first the log (ALLOWED) and later the pass rule allows the communication. As per the default actions, other communication will be DENIED and logged in the same destination (ALERT flow log).

### Logging Configuration

- VPC Flow Logs are configured and sent to a CloudWatch Log group. Amazon S3 and Amazon Kinesis Firehose can also be used as a logging destination.
- AWS Network firewall logs are also configured - both **ALERT** and **FLOW** - to respective AWS Cloudwatch Log Groups. Amazon S3 or Amazon Kinesis Firehose can also be used as a logging destination.

## Target Architecture

![Architecture diagram](./images/architecture\_diagram.png)

### References

- AWS Reference Architecture - [Inspection Deployment Models with AWS Network Firewall](https://d1.awsstatic.com/architecture-diagrams/ArchitectureDiagrams/inspection-deployment-models-with-AWS-network-firewall-ra.pdf).
- AWS Documentation - [Evaluation order for stateful rule groups](https://docs.aws.amazon.com/network-firewall/latest/developerguide/suricata-rule-evaluation-order.html)

### Cleanup

Remember to clean up after your work is complete. You can do that by doing `terraform destroy`.

Note that this command will delete all the resources previously created by Terraform.

## Security

See [CONTRIBUTING](CONTRIBUTING.md) for more information.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.28.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.59.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_network_firewall"></a> [network\_firewall](#module\_network\_firewall) | aws-ia/networkfirewall/aws | 0.1.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | aws-ia/vpc/aws | 4.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.anfwlogs_lg_alert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.anfwlogs_lg_flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_instance_profile.ec2_ssm_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy_attachment.ssm_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.role_ec2_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vpc_flowlogs_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vpc_flowlogs_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_instance.ec2_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_kms_key.log_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_networkfirewall_firewall_policy.anfw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_rule_group.allow_domains](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.allow_icmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.drop_remote](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_route_table.vpc_igw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.vpc_igw_rt_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_ami.amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy_kms_logs_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy_role_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy_rolepolicy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/internet_gateway) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region to create the environment. | `string` | `"eu-west-1"` | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | VPC's CIDR block. | `string` | `"10.0.0.0/24"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project Name, used as identifer when creating resources. | `string` | `"anfw-strict-rule"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type of the instances created. | `string` | `"t2.micro"` | no |
| <a name="input_number_azs"></a> [number\_azs](#input\_number\_azs) | Number of Availability Zones to create resources in the VPC. | `number` | `1` | no |
| <a name="input_subnet_cidr_blocks"></a> [subnet\_cidr\_blocks](#input\_subnet\_cidr\_blocks) | Subnet CIDR blocks. | `map(list(string))` | <pre>{<br>  "endpoints": [<br>    "10.0.0.144/28",<br>    "10.0.0.160/28",<br>    "10.0.0.176/28"<br>  ],<br>  "inspection": [<br>    "10.0.0.0/28",<br>    "10.0.0.16/28",<br>    "10.0.0.32/28"<br>  ],<br>  "private": [<br>    "10.0.0.96/28",<br>    "10.0.0.112/28",<br>    "10.0.0.128/28"<br>  ],<br>  "public": [<br>    "10.0.0.48/28",<br>    "10.0.0.64/28",<br>    "10.0.0.80/28"<br>  ]<br>}</pre> | no |
| <a name="input_vpcflowlog_type"></a> [vpcflowlog\_type](#input\_vpcflowlog\_type) | The type of traffic to log in VPC Flow Logs. | `string` | `"ALL"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->