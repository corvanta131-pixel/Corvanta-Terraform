output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile for the EC2 instance"
  value       = aws_iam_instance_profile.corvanta_ec2.name
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile for the EC2 instance"
  value       = aws_iam_instance_profile.corvanta_ec2.arn
}
