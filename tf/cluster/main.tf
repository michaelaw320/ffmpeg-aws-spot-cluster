data "aws_ami" "amzn_linux_2" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    bucket = var.common_infrastructure_tfstate_bucket
    key    = var.common_infrastructure_tfstate_key
    region = var.common_infrastructure_bucket_region
  }
}

data "template_file" "user_data" {
  count    = var.instance_count
  template = file("${path.module}/user_data_template.tpl")

  vars = {
    s3_ffmpeg_bin_path      = var.s3_ffmpeg_bin_path
    source_code_branch      = var.source_code_branch
    source_code_repository  = var.source_code_repository
    node_num                = count.index
    total_node              = var.instance_count
    input_s3_path           = var.input_s3_path
    output_s3_path          = var.output_s3_path
    encoder_setting_s3_path = var.encoder_setting_s3_path

  }
}

resource "aws_spot_instance_request" "cluster_member" {
  count                           = var.instance_count
  ami                             = data.aws_ami.amzn_linux_2.id
  instance_type                   = var.instance_type
  spot_type                       = "persistent"
  instance_interruption_behaviour = "hibernate"

  ebs_optimized = true
  key_name      = var.instance_ssh_key

  vpc_security_group_ids = [data.terraform_remote_state.common.outputs.sg_instances_id]
  subnet_id              = element(data.terraform_remote_state.common.outputs.vpc_public_subnets, count.index)

  associate_public_ip_address = true
  user_data                   = data.template_file.user_data[count.index].rendered

  iam_instance_profile = data.terraform_remote_state.common.outputs.ec2_instance_profile_name

  root_block_device {
    volume_size           = var.ebs_volume_size
    delete_on_termination = true
  }

  tags = {
    Project = "${var.prefix}-cluster"
    Name    = "${var.prefix}-cluster-${count.index}"
  }
}
