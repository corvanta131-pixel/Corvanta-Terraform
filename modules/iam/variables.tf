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

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket the EC2 instance needs access to"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue the EC2 instance needs access to"
  type        = string
}
