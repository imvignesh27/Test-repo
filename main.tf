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

# IAM Users
resource "aws_iam_user" "cis-user1" {
  name = var.iam_user_name
}

resource "aws_iam_user" "non-cis-user1" {
  name = var.non_cis_user_name
}

# S3 Buckets
resource "aws_s3_bucket" "cis_bucket" {
  bucket = var.s3_bucket_name
  tags = {
    Name = "CIS Terraform S3 Bucket"
  }
}

resource "aws_s3_bucket" "noncis_bucket" {
  bucket = var.noncis_bucket_name
  tags = {
    Name = "Non-CIS Terraform S3 Bucket"
  }
}

# Latest Amazon Linux AMI for EC2
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instances
resource "aws_instance" "cis_instance" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = var.ec2_instance_type
  tags = {
    Name = "CIS Terraform EC2"
  }
}

resource "aws_instance" "cis_instance2" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = var.ec2_instance_type
  tags = {
    Name = "Non-CIS Terraform EC2 Instance 2"
  }
}
