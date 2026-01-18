# IAM: Password Policies (CIS 1.7, 1.8)
resource "aws_iam_account_password_policy" "cis_policy" {
  minimum_password_length        = 14    # CIS 1.7
  password_reuse_prevention      = 24    # CIS 1.8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  max_password_age               = 90
}
