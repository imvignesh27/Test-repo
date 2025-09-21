output "cis_iam_user_name" {
  value       = aws_iam_user.cis-user1.name
  description = "The name of the CIS IAM user."
}

output "noncis_iam_user_name" {
  value       = aws_iam_user.non-cis-user1.name
  description = "The name of the non-CIS IAM user."
}

output "cis_s3_bucket_name" {
  value       = aws_s3_bucket.cis_bucket.id
  description = "The name of the CIS S3 bucket."
}

output "noncis_s3_bucket_name" {
  value       = aws_s3_bucket.noncis_bucket.id
  description = "The name of the non-CIS S3 bucket."
}

output "cis_ec2_instance_id" {
  value       = aws_instance.cis_instance.id
  description = "The instance ID of the CIS EC2 instance."
}

output "cis_ec2_instance2_id" {
  value       = aws_instance.cis_instance2.id
  description = "The instance ID of the second CIS EC2 instance."
}
