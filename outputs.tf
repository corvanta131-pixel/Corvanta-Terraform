output "vpc_id" {
  description = "ID of the Corvanta VPC"
  value       = module.network.vpc_id
}

output "backend_instance_id" {
  description = "ID of the Corvanta backend EC2 instance"
  value       = module.compute.backend_instance_id
}

output "backend_public_ip" {
  description = "Public IP of the Corvanta backend EC2 instance"
  value       = module.compute.backend_public_ip
}

output "backend_elastic_ip" {
  description = "Elastic IP assigned to the Corvanta backend"
  value       = module.compute.backend_elastic_ip
}

output "s3_bucket_name" {
  description = "Name of the Corvanta S3 bucket"
  value       = aws_s3_bucket.practice.bucket
}

output "sqs_queue_url" {
  description = "URL of the Corvanta SQS queue"
  value       = aws_sqs_queue.corvanta.url
}