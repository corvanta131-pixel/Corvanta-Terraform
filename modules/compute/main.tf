
resource "aws_security_group" "backend" {
  name        = "corvanta-practice-backend-sg"
  description = "Security group for Corvanta practice backend EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet for practice"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH for practice administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "corvanta-backend-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_key_pair" "ec2" {
  key_name   = "corvanta-practice-ec2-key"
  public_key = file(pathexpand(var.public_key_path))

  tags = {
    Name        = "corvanta-practice-ec2-key"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "backend" {
  ami                         = "ami-03f92a7a8a26c81af"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.backend.id]
  key_name                    = aws_key_pair.ec2.key_name
  iam_instance_profile        = var.iam_instance_profile_name
  associate_public_ip_address = true

  tags = {
    Name        = "corvanta-backend"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_eip" "backend" {
  domain = "vpc"

  tags = {
    Name        = "corvanta-backend-eip"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_eip_association" "backend" {
  instance_id   = aws_instance.backend.id
  allocation_id = aws_eip.backend.id
}
