# Main Region
provider "aws" {
  region  = "aws-region-here"
  version = "~> 2"
}

# Other Region
# Uncomment lines below, adjust as necessary
# to use, on the module, add providers block
//provider "aws" {
//  region  = "eu-west-1"
//  version = "~> 2"
//  alias   = "eu-west-1"
//}

# Where this terraform state will reside
terraform {
  required_version = "0.12.16"

  backend "s3" {
    bucket = "your-bucket-here"
    key    = "where-in-bucket-youd-store-the-state"
  }
}

locals {
  prefix = "change-this-too-to-your-liking"
}

# Global resources, region does not matter
module "instance_profile" {
  source = "../modules/instance-profile"

  prefix = local.prefix
}

# Optional, comment out if you're not interested in applying terraform on AWS
module "terraform_role" {
  source = "../modules/terraform-role"

  prefix = local.prefix
  #allowed_users = ["put ARN to IAM User if you want to assume the role"]
}

# Region specific resources, to create in other regions, see above providers
module "vpc_sg" {
  source = "../modules/vpc-sg"

  prefix  = local.prefix
  vpc_azs = ["fill-in-with-aws-availability-zones-in-your-region-that-supports-the-instance-type"]
}

