terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# --- IAM CONFIGURATION ---

# NOTE: Password Policy is Account-Wide (Applies to ALL users)
# This satisfies CIS 1.7 & 1.8
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  password_reuse_prevention      = 24
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  max_password_age               = 90
}

# CIS User (Targeted)
resource "aws_iam_user" "cis_user" {
  name = var.iam_user_name
  tags = { Name = "CIS-User" }
}

# Non-CIS User (Basic)
resource "aws_iam_user" "non_cis_user" {
  name = var.non_cis_user_name
  tags = { Name = "Non-CIS-User" }
}

# --- S3 CONFIGURATION ---

# 1. CIS Compliant Bucket
resource "aws_s3_bucket" "cis_bucket" {
  bucket = var.s3_bucket_name
}

# CIS 2.1.4: Block Public Access (ONLY for cis_bucket)
resource "aws_s3_bucket_public_access_block" "cis_block" {
  bucket = aws_s3_bucket.cis_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CIS 2.1.1: Deny HTTP / Enforce SSL (ONLY for cis_bucket)
resource "aws_s3_bucket_policy" "cis_ssl_policy" {
  bucket = aws_s3_bucket.cis_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSSLRequestsOnly"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [
        aws_s3_bucket.cis_bucket.arn,
        "${aws_s3_bucket.cis_bucket.arn}/*"
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

# 2. Non-CIS Bucket (No extra policies attached)
resource "aws_s3_bucket" "non_cis_bucket" {
  bucket = var.noncis_bucket_name
}

# --- EC2 CONFIGURATION ---

# Data Source for AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# CIS Security Group (Restricted)
resource "aws_security_group" "cis_sg" {
  name        = "cis-restricted-sg"
  description = "CIS Compliant SG"
  
  # CIS 5.3: No 0.0.0.0/0 on port 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"] # Internal Network Only
  }
}

# 1. CIS Compliant EC2 Instance
resource "aws_instance" "cis_instance" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.cis_sg.id]

  # CIS 5.7: Enforce IMDSv2 (ONLY for cis_instance)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" 
  }

  tags = {
    Name = "CIS Terraform EC2"
  }
}

# 2. Non-CIS EC2 Instance (Standard)
resource "aws_instance" "non_cis_instance" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = var.ec2_instance_type

  # No metadata_options block means it defaults to Optional (IMDSv1 allowed)
  
  tags = {
    Name = "Non-CIS Terraform EC2 Instance"
  }
}
