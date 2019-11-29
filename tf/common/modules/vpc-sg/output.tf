output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "CIDR block of this VPC"
}

output "vpc_ipv6_cidr_block" {
  value       = module.vpc.vpc_ipv6_cidr_block
  description = "IPv6 CIDR block of this VPC"
}

output "vpc_public_subnets" {
  value       = module.vpc.public_subnets
  description = "List of public subnet available in VPC"
}

output "vpc_route_tables" {
  value       = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids, list(module.vpc.vpc_main_route_table_id))
  description = "List of route tables ID (private and public)"
}

output "sg_instances_id" {
  value       = module.instance_security_group.this_security_group_id
  description = "Security Group ID for Instances"
}
