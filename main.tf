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

# -----------------------
# Random suffix (unique bucket names)
# -----------------------
resource "random_id" "suffix" {
  byte_length = 4
}

# -----------------------
# S3 Bucket with CIS settings
# -----------------------
resource "aws_s3_bucket" "cis_bucket" {
  bucket        = "cis-compliance-bucket-${random_id.suffix.hex}"
  force_destroy = true # ensures bucket + objects get destroyed with terraform destroy

  tags = {
    Name        = "CIS_Compliance_Bucket"
    Environment = "Dev"
  }
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

# Enable server-side encryption (SSE-S3 managed keys)
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.cis_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------
# AWS Config Setup
# -----------------------

# IAM Role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "aws_config_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "config.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# Config Recorder
resource "aws_config_configuration_recorder" "recorder" {
  name     = "default"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
  }
}

# Delivery Channel
resource "aws_config_delivery_channel" "channel" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.cis_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.recorder]
}

# Enable Config Recorder
resource "aws_config_configuration_recorder_status" "recorder_status" {
  is_enabled = true
  name       = aws_config_configuration_recorder.recorder.name
}

# Compliance Rule: Ensure S3 Buckets have SSE enabled
resource "aws_config_config_rule" "s3_encryption_rule" {
  name = "s3-bucket-server-side-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [
    aws_config_configuration_recorder.recorder,
    aws_config_delivery_channel.channel,
    aws_config_configuration_recorder_status.recorder_status
  ]
}
