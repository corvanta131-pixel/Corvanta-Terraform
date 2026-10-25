variable "project_name" {
  description = "Project name for Corvanta infrastructure"
  type        = string
  default     = "Corvanta"
}

variable "environment" {
  description = "Deployment environment (e.g. production)"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}

variable "account_id" {
  description = "AWS account ID appended to the bucket name to keep it globally unique"
  type        = string
  default     = ""
}
