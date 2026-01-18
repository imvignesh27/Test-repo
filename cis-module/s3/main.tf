#S3: Public Access & Enryption (CIS 2.1.1, 2.1.4)
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "cis-compliant-storage-bucket"
}

# CIS 2.1.4 - Block all public access
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CIS 2.1.1 - Deny non-HTTPS requests
resource "aws_s3_bucket_policy" "deny_http" {
  bucket = aws_s3_bucket.secure_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "s3:*"
      Effect    = "Deny"
      Principal = "*"
      Resource  = ["${aws_s3_bucket.secure_bucket.arn}/*", aws_s3_bucket.secure_bucket.arn]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}
