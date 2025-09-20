output "iam_user_name" {
  value = aws_iam_user.cis_user1.name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.cis_bucket.id
}

output "ec2_instance_id" {
  value = aws_instance.cis_instance.id
}
