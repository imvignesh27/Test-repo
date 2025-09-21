variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"
}

variable "iam_user_name" {
  description = "IAM User name to create (CIS)"
  type        = string
  default     = cis-user-1
}

variable "non_cis_user_name" {
  description = "IAM User name to create (Non-CIS)"
  type        = string
  default     = non-cis-user-1
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
