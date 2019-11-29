module "instance_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.2.0"

  name   = "${var.prefix}-ec2-sg"
  vpc_id = module.vpc.vpc_id


  # Ingress for SSH
  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]
  ingress_rules            = ["ssh-tcp"]

  # Allow all egress
  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks = ["::/0"]
  egress_rules            = ["all-all"]

  tags = {
    Project = "${var.prefix}-common"
  }
}