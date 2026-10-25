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

variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = null
}

variable "visibility_timeout_seconds" {
  description = "Seconds a received message is hidden from other consumers"
  type        = number
  default     = 60
}

variable "message_retention_seconds" {
  description = "Seconds a message is kept in the queue"
  type        = number
  default     = 86400
}
