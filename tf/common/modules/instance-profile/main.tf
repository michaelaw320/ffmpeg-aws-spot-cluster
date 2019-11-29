resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.prefix}-instance-profile"
  path = "/"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name               = "${var.prefix}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  description = "Instance role for ffmpeg-aws-spot-cluster project."

  tags = {
    Project = "${var.prefix}-common"
  }
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role_policy" "s3" {
  role   = aws_iam_role.instance_role.id
  name   = "${var.prefix}-s3-permissions"
  policy = data.aws_iam_policy_document.s3.json
}

data "aws_iam_policy_document" "s3" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:PutObjectTagging",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ec2" {
  role   = aws_iam_role.instance_role.id
  name   = "${var.prefix}-ec2-permissions"
  policy = data.aws_iam_policy_document.ec2.json
}

data "aws_iam_policy_document" "ec2" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "ec2:CancelSpotInstanceRequests",
      "ec2:DeleteVolume",
      "ec2:DescribeInstances",
      "ec2:TerminateInstances",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:StopInstances",
    ]
    resources = ["*"]
  }
}
