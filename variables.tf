terraform {
  experiments = [variable_validation]
}

variable "name" {
  type        = string
  description = "Name that will be used in resources names and tags."
  default     = "terraform-aws-ssh-bastion"
}

variable "instance_type" {
  type        = string
  description = "The instance type of the EC2 instance."
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge"], var.instance_type)
    error_message = "Must be a valid Amazon EC2 instance type."
  }
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC."
}

variable "vpc_subnets" {
  type        = list(string)
  description = "A list of VPC subnet IDs."
}

variable "cidr_block" {
  type        = string
  description = "The CIDR IP range that is permitted to SSH to bastion instance. Note: a value of 0.0.0.0/0 will allow access from ANY IP address."
  default     = "0.0.0.0/0"

  validation {
    condition     = can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/(0|[1-9]|1[0-9]|2[0-9]|3[0-2]))$", var.cidr_block))
    error_message = "CIDR parameter must be in the form x.x.x.x/0-32."
  }
}
