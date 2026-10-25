resource "aws_sqs_queue" "corvanta" {
  name = coalesce(var.queue_name, "${var.project_name}-${var.environment}-queue")

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds

  sqs_managed_sse_enabled = true

  tags = {
    Name        = coalesce(var.queue_name, "${var.project_name}-${var.environment}-queue")
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
