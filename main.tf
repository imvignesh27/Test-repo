terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Random suffix to avoid bucket name conflicts
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 bucket for CIS compliance
resource "aws_s3_bucket" "cis_bucket" {
  bucket = "cis-compliance-bucket-${random_id.suffix.hex}"

  # Default in AWS: ACLs disabled (BucketOwnerEnforced)
  # which is compliant with CIS.
  force_destroy = false

  tags = {
    Name        = "CIS_Compliance_Bucket"
    Environment = "Dev"
  }
}

# Block all forms of public access
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.cis_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.cis_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable default encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.cis_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
