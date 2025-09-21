variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "iam_user_name" {
  description = "IAM User name to create (CIS)"
  type        = string
}

variable "non_cis_user_name" {
  description = "IAM User name to create (Non-CIS)"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name (CIS, must be unique)"
  type        = string
}

variable "noncis_bucket_name" {
  description = "S3 bucket name (Non-CIS, must be unique)"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 Instance type"
  type        = string
}
