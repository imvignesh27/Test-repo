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

# ----------------------------
# AWS Config Role & Policy
# ----------------------------
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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# ----------------------------
# AWS Config Recorder & Delivery
# ----------------------------
resource "aws_config_configuration_recorder" "recorder" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "delivery" {
  name           = "config-delivery"
  s3_bucket_name = aws_s3_bucket.cis_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_configuration_recorder_status" "status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.delivery]
}

# ----------------------------
# Bucket Policy for AWS Config
# ----------------------------
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.cis_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.cis_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.cis_bucket.arn
      }
    ]
  })
}
