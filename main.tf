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

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}

# Random suffix for bucket uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket
resource "aws_s3_bucket" "cis_bucket" {
  bucket = "cis-compliance-bucket-${random_id.suffix.hex}"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "CIS_Compliance_Bucket"
    Environment = "Dev"
  }
}

# Public access block for bucket
resource "aws_s3_bucket_public_access_block" "cis_bucket_block" {
  bucket                  = aws_s3_bucket.cis_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Config
resource "aws_iam_role" "config_role" {
  name = "ConfigRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for Config
resource "aws_iam_policy" "config_policy" {
  name        = "ConfigPolicy"
  description = "Policy for AWS Config to access resources"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
          "sns:*",
          "config:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach_config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = aws_iam_policy.config_policy.arn
}

# Config Recorder
resource "aws_config_configuration_recorder" "config_recorder" {
  name     = "default"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

# Delivery Channel
resource "aws_config_delivery_channel" "delivery_channel" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.cis_bucket.bucket
  config_snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }
}

# Ensure recorder is active
resource "aws_config_configuration_recorder_status" "recorder_status" {
  name    = aws_config_configuration_recorder.config_recorder.name
  is_enabled = true
}
