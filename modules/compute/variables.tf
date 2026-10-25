variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "iam_instance_profile_name" {
  type = string
}

variable "ssh_public_key_path" {
  type        = string
  description = "Absolute path to the public SSH key (.pub) registered as the AWS key pair"
  default     = "/home/louis/.ssh/corvanta-ec2.pub"

  validation {
    condition     = endswith(var.ssh_public_key_path, ".pub")
    error_message = "ssh_public_key_path must point at the .pub file, never the private key."
  }
}

variable "admin_cidr_block" {
  type        = string
  description = "IPv4 host CIDR (in /32 notation) permitted to reach SSH on the backend instance"

  validation {
    condition     = can(cidrhost(var.admin_cidr_block, 0))
    error_message = "admin_cidr_block must be a valid IPv4 CIDR block, e.g. 203.0.113.10/32."
  }

  validation {
    condition     = var.admin_cidr_block != "0.0.0.0/0"
    error_message = "admin_cidr_block must be a restricted CIDR block, not 0.0.0.0/0."
  }

  validation {
    condition     = try(split("/", var.admin_cidr_block)[1], "") == "32"
    error_message = "admin_cidr_block must be a single IPv4 host address in /32 notation."
  }
}

variable "ami_name_filter" {
  type        = string
  description = "SSM parameter path used to discover the latest Ubuntu AMI"
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "key_pair_name" {
  type        = string
  description = "Name of the AWS key pair for SSH access"
  default     = "corvanta-ec2"
}
