variable "aws_region" {
  type        = string
  description = "AWS region for the Corvanta infrastructure"
  default     = "eu-central-1"
}

variable "project_name" {
  type        = string
  description = "Project name used for Corvanta infrastructure"
  default     = "Corvanta"
}

variable "environment" {
  type        = string
  description = "Deployment environment (production, staging, etc.)"
  default     = "production"

  validation {
    condition     = contains(["production", "staging"], var.environment)
    error_message = "Environment must be production or staging."
  }
}

variable "backend_instance_type" {
  type        = string
  description = "EC2 instance type for the Corvanta backend"
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Absolute path to the public SSH key (.pub) uploaded to AWS for the Corvanta EC2 instance. The matching private key stays on this machine only and is never stored in Terraform."
  default     = "/home/louis/.ssh/corvanta-ec2.pub"

  validation {
    condition     = endswith(var.ssh_public_key_path, ".pub")
    error_message = "ssh_public_key_path must point at the .pub file, never the private key."
  }
}

variable "admin_cidr_block" {
  type        = string
  description = "IPv4 host CIDR (in /32 notation) permitted to reach SSH on the Corvanta backend, e.g. 203.0.113.10/32. Set it in terraform.tfvars; never use 0.0.0.0/0."

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
