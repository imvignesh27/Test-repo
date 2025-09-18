terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_config_config_rule" "s3_version_lifecycle" {
  name = "s3-version-lifecycle-policy-check"
  source {
    owner             = "AWS"
    source_identifier = "S3_VERSION_LIFECYCLE_POLICY_CHECK"
  }
}

resource "aws_config_remediation_configuration" "s3_remediate" {
  config_rule_name = aws_config_config_rule.s3_version_lifecycle.name
  target_id        = "AWS-UpdateS3BucketVersioning"   # Built-in SSM Document for remediation
  target_type      = "SSM_DOCUMENT"
  
  automatic = true

  parameters = {
    BucketName = {
      static_value = {
        values = ["${aws_s3_bucket.example_bucket.bucket}"]
      }
    }
    VersioningConfiguration = {
      static_value = {
        values = ["Enabled"]
      }
    }
  }
}
