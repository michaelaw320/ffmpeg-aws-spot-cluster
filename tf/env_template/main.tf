# Region Setting
provider "aws" {
  region  = "your-choice-of-region"
  version = "~> 2"
}

# Where this terraform state will reside
terraform {
  required_version = "0.12.16"

  backend "s3" {
    bucket = "where-you-want-to-put-state-in"
    key    = "where-you-want-to-put-state-in"
    region = "the-s3-region"
  }
}

module "cluster" {
  source = "../cluster"

  prefix = "created-resources-prefix"

  common_infrastructure_tfstate_bucket = "which-bucket-did-you-put-your-common-tfstate-in"
  common_infrastructure_tfstate_key    = "same/one/as/you-defined-on-the-backend-section-in-common.tfstate"
  common_infrastructure_bucket_region  = "same-one-as-defined-in-common"

  encoder_setting_s3_path = "s3://bucket-name/encoder-config.json"
  instance_count          = 1
  instance_type           = "c5.2xlarge"
  input_s3_path           = "s3://bucket-name/input-folder/"
  output_s3_path          = "s3://can-be-different-bucket-or-same/output-folder/"
}