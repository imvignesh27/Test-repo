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

# IAM User
resource "aws_iam_user" "cis_user1" {
  name = var.iam_user_name
}

# S3 Bucket
resource "aws_s3_bucket" "cis_bucket" {
  bucket = var.s3_bucket_name
  tags = {
    Name = "CIS Terraform S3 Bucket"
  }
}

# EC2 Instance
resource "aws_instance" "cis_instance" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  tags = {
    Name = "CIS Terraform EC2"
  }
}
