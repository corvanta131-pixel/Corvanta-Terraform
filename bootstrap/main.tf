terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = "corvanta-terraform-state-${var.aws_account_id}"
  lock_table_name   = "corvanta-terraform-locks"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    {
      Project     = "Corvanta"
      Environment = "production"
      Purpose     = "Terraform remote state"
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::${local.state_bucket_name}",
          "arn:aws:s3:::${local.state_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  tags = {
    Project     = "Corvanta"
    Environment = "production"
    Purpose     = "Terraform state locking"
    ManagedBy   = "Terraform"
  }
}

output "state_bucket_arn" {
  description = "ARN of the dedicated Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "state_bucket_name" {
  description = "Name of the dedicated Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  description = "Name of the DynamoDB state-locking table"
  value       = aws_dynamodb_table.terraform_locks.name
}