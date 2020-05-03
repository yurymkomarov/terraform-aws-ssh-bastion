locals {
  key_pair = {
    private = tls_private_key.this.private_key_pem
    public  = tls_private_key.this.public_key_openssh
  }
}

resource "random_id" "this" {
  byte_length = 1

  keepers = {
    name          = var.name
    instance_type = var.instance_type
    vpc_id        = var.vpc_id
    vpc_subnets   = join("", var.vpc_subnets)
    cidr_blocks   = var.cidr_block
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = "4096"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret" "this" {
  name = "${var.name}-${random_id.this.hex}"

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(local.key_pair)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-${random_id.this.hex}"
  public_key = tls_private_key.this.public_key_openssh

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  default_cooldown          = 60
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.this.id
  min_size                  = 1
  max_size                  = 1
  name                      = "${var.name}-${random_id.this.hex}"
  vpc_zone_identifier       = var.vpc_subnets

  tags = [
    {
      key                 = "Name"
      value               = var.name
      propagate_at_launch = true
    },
    {
      key                 = "Workspace"
      value               = terraform.workspace
      propagate_at_launch = true
    }
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "this" {
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.this.name
  image_id                    = data.aws_ami.this.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.this.key_name
  name                        = "${var.name}-${random_id.this.hex}"
  security_groups             = [aws_security_group.this.id]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-${random_id.this.hex}"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-${random_id.this.hex}"
  path = "/"
  role = aws_iam_role.this.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name               = "${var.name}-${random_id.this.hex}"
  path               = "/"

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}-${random_id.this.hex}"
  policy = data.aws_iam_policy_document.role_policy.json
  role   = aws_iam_role.this.id

  lifecycle {
    create_before_destroy = true
  }
}
