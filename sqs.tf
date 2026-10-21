# ============================================================
# CORVANTA SQS QUEUE
# ============================================================

resource "aws_sqs_queue" "corvanta" {
  name = "corvanta-practice-queue"

  visibility_timeout_seconds = 60

  message_retention_seconds = 86400

  tags = {
    Project     = "Corvanta"
    Environment = "practice"
    ManagedBy   = "Terraform"
  }
}