locals {
  bucket_name = lower(join("-", compact(["${var.project_name}-${var.environment}-storage", var.account_id])))
}

resource "aws_s3_bucket" "corvanta" {
  bucket = local.bucket_name

  tags = merge(
    {
      Name        = local.bucket_name
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

resource "aws_s3_bucket_public_access_block" "corvanta" {
  bucket = aws_s3_bucket.corvanta.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "corvanta" {
  bucket = aws_s3_bucket.corvanta.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "corvanta" {
  bucket = aws_s3_bucket.corvanta.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "corvanta" {
  bucket = aws_s3_bucket.corvanta.id

  rule {
    id     = "retain-current-expire-old-versions-and-abort-incomplete-multipart"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
