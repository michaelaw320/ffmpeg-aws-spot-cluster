variable "prefix" {
  description = "Prefix for all created resources"
}

// VPC Options
variable "vpc_cidr" {
  description = "IPv4 CIDR Notation for VPC IP range"
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "VPC Availability Zones"
  type        = list(string)
}
