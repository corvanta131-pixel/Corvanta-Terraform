output "backend_instance_id" {
  description = "Corvanta backend EC2 instance ID"
  value       = aws_instance.backend.id
}

output "backend_public_ip" {
  description = "Corvanta backend public IP"
  value       = aws_instance.backend.public_ip
}

output "backend_private_ip" {
  description = "Corvanta backend private IP"
  value       = aws_instance.backend.private_ip
}

output "backend_elastic_ip" {
  description = "Corvanta backend Elastic IP"
  value       = aws_eip.backend.public_ip
}

output "backend_security_group_id" {
  description = "Corvanta backend security group ID"
  value       = aws_security_group.backend.id
}

output "backend_ami_id" {
  description = "AMI used by the Corvanta backend instance"
  value       = data.aws_ssm_parameter.ubuntu_ami.value
}
