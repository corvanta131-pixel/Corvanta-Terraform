variable "aws_account_id" {
  description = "AWS account ID (used in bucket name for uniqueness)"
  type        = string
  default     = "072718160542"
}

variable "aws_region" {
  description = "AWS region for remote state resources"
  type        = string
  default     = "eu-central-1"
}

variable "additional_tags" {
  description = "Additional tags to apply to bootstrap resources"
  type        = map(string)
  default     = {}
}
