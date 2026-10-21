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
  description = "Deployment environment"
  default     = "practice"

  validation {
    condition     = contains(["practice", "development", "staging", "production"], var.environment)
    error_message = "Environment must be practice, development, staging, or production."
  }
}

variable "backend_instance_type" {
  type        = string
  description = "EC2 instance type for the Corvanta backend"
  default     = "t3.micro"
}