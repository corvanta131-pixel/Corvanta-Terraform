resource "aws_iam_role" "corvanta_ec2" {
  name = "corvanta-practice-ec2-role"

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
    Project     = "Corvanta"
    Environment = "practice"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_instance_profile" "corvanta_ec2" {
  name = "corvanta-practice-ec2-profile"

  role = aws_iam_role.corvanta_ec2.name
}

resource "aws_iam_policy" "corvanta_s3" {
  name        = "corvanta-practice-s3-policy"
  description = "S3 permissions for the Corvanta practice EC2 application"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.practice.arn
      },
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "${aws_s3_bucket.practice.arn}/*"
      }
    ]
  })

  tags = {
    Project     = "Corvanta"
    Environment = "practice"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "corvanta_s3" {
  role       = aws_iam_role.corvanta_ec2.name
  policy_arn = aws_iam_policy.corvanta_s3.arn
}