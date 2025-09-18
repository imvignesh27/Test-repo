provider "aws" {
  region = "ap-south-1"
}

# Create CIS-compliant S3 bucket
resource "aws_s3_bucket" "cis_bucket" {
  bucket = "cis-compliance-bucket-${random_id.suffix.hex}"
}

# To avoid name conflicts (since S3 bucket names must be unique)
resource "random_id" "suffix" {
  byte_length = 4
}

# Bucket ACL (private)
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.cis_bucket.id
  acl    = "private"
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.cis_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.cis_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.cis_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
