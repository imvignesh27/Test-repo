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

  force_destroy = true

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

# -------------------------------
# AWS Config Setup
# -------------------------------

# IAM Role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "ConfigRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_role_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# Configuration Recorder
resource "aws_config_configuration_recorder" "recorder" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config_role.arn
}

# Detect existing delivery channels
data "aws_config_delivery_channels" "existing" {}

# Create delivery channel ONLY if none exist
resource "aws_config_delivery_channel" "delivery" {
  count          = length(data.aws_config_delivery_channels.existing.names) == 0 ? 1 : 0
  name           = "config-delivery"
  s3_bucket_name = aws_s3_bucket.cis_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.recorder]
}

# Recorder status
resource "aws_config_configuration_recorder_status" "recorder_status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.delivery]
}

# Example compliance rule for S3 encryption
resource "aws_config_config_rule" "s3_encryption" {
  name = "s3-bucket-server-side-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}
