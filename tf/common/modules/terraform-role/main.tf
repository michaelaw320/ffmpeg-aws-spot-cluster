resource "aws_iam_role" "terraform_role" {
  name               = "${var.prefix}-terraform"
  description        = "Terraform IAM role for ffmpeg-aws-spot-cluster project."
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.sts_policy.json

  tags = {
    Project = "${var.prefix}-common"
  }
}

# Trust relationships
data "aws_iam_policy_document" "sts_policy" {
  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = var.allowed_users
    }
  }
}

# Policy attachments

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.terraform_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Inline Policy

resource "aws_iam_role_policy" "iam_access" {
  role   = aws_iam_role.terraform_role.id
  name   = "${var.prefix}-terraform-iam"
  policy = data.aws_iam_policy_document.iam_access.json
}

data "aws_iam_policy_document" "iam_access" {
  version = "2012-10-17"

  statement {
    sid    = "ReadOnlyPermissions"
    effect = "Allow"
    actions = [
      "iam:GenerateServiceLastAccessedDetails",
      "iam:GenerateCredentialReport",
      "iam:Get*",
      "iam:List*",
      "iam:Add*",
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::*:role/${var.prefix}*",
      "arn:aws:iam::*:instance-profile/${var.prefix}*",
      "arn:aws:iam::*:policy/${var.prefix}*",
    ]
  }
  statement {
    sid    = "CreateModifyPermissions"
    effect = "Allow"
    actions = [
      "iam:Create*",
      "iam:Update*",
      "iam:Put*",
      "iam:Attach*",
      "iam:Detach*",
      "iam:DeleteRolePolicy",
      "iam:DeleteInstanceProfile",
      "iam:DeletePolicyVersion",
      "iam:DeleteRole",
      "iam:DeletePolicy",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagRole",
      "iam:UntagRole",
    ]
    resources = [
      "arn:aws:iam::*:role/${var.prefix}*",
      "arn:aws:iam::*:instance-profile/${var.prefix}*",
      "arn:aws:iam::*:policy/${var.prefix}*"
    ]
  }
  statement {
    sid    = "DenyPermissions"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:DeleteUser",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "s3" {
  role   = aws_iam_role.terraform_role.id
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
