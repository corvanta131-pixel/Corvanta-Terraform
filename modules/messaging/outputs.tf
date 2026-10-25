output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.corvanta.url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.corvanta.arn
}

output "sqs_queue_name" {
  description = "Name of the SQS queue"
  value       = aws_sqs_queue.corvanta.name
}
