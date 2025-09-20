variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "iam_user_name" {
  description = "IAM user name"
  type        = string
  default     = "cis_user1"
}

variable "s3_bucket_name" {
  description = "S3 bucket name (must be unique globally)"
  type        = string
}

variable "ec2_ami" {
  description = "AMI ID to use for EC2 instance"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
}
