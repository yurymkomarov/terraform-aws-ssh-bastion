data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }
}
