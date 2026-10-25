resource "aws_iam_role" "corvanta_ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_instance_profile" "corvanta_ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"

  role = aws_iam_role.corvanta_ec2.name

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_policy" "corvanta_s3" {
  name        = "${var.project_name}-${var.environment}-s3-policy"
  description = "S3 permissions for the Corvanta EC2 application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "corvanta_s3" {
  role       = aws_iam_role.corvanta_ec2.name
  policy_arn = aws_iam_policy.corvanta_s3.arn
}

resource "aws_iam_policy" "corvanta_sqs" {
  name        = "${var.project_name}-${var.environment}-sqs-policy"
  description = "SQS permissions for the Corvanta EC2 application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "corvanta_sqs" {
  role       = aws_iam_role.corvanta_ec2.name
  policy_arn = aws_iam_policy.corvanta_sqs.arn
}
