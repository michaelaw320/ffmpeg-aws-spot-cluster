output "ec2_instance_profile_name" {
  value       = module.instance_profile.ec2_instance_profile_name
  description = "Instance Profile name to attach to EC2"
}

output "ec2_instance_role_arn" {
  value       = module.instance_profile.ec2_instance_role_arn
  description = "Role ARN for EC2 instance"
}

output "terraform_role_arn" {
  value       = module.terraform_role.terraform_role_arn
  description = "Role to run terraform safely"
}

output "vpc_id" {
  value       = module.vpc_sg.vpc_id
  description = "VPC ID"
}

output "vpc_cidr_block" {
  value       = module.vpc_sg.vpc_cidr_block
  description = "CIDR block of this VPC"
}

output "vpc_ipv6_cidr_block" {
  value       = module.vpc_sg.vpc_ipv6_cidr_block
  description = "IPv6 CIDR block of this VPC"
}

output "vpc_public_subnets" {
  value       = module.vpc_sg.vpc_public_subnets
  description = "List of public subnet available in VPC"
}

output "vpc_route_tables" {
  value       = module.vpc_sg.vpc_route_tables
  description = "List of route tables ID (private and public)"
}

output "sg_instances_id" {
  value       = module.vpc_sg.sg_instances_id
  description = "Security Group ID for Instances"
}
