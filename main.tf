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

resource "aws_instance" "cis_instance" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = var.ec2_instance_type
  tags = {
    Name = "CIS Terraform EC2"
  }
}

resource "aws_instance" "cis_instance" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  tags = {
    Name = "CIS Terraform EC2"
  }
}
