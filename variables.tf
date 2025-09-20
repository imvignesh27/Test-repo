# AWS Region
variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
}

# S3 Bucket Name
variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

# EC2 AMI ID
variable "ec2_ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

# EC2 Instance Type
variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
