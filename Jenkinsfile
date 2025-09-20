pipeline {
  agent any
  environment {
    AWS_REGION = 'ap-south-1'
  }
  stages {
    stage('Remediate EC2 IMDSv2') {
      steps {
        script {
          def ec2Status = sh(
            script: "aws configservice describe-compliance-by-config-rule --config-rule-names ec2-imdsv2-check --region $AWS_REGION --query 'ComplianceByConfigRules[0].Compliance.ComplianceType' --output text",
            returnStdout: true
          ).trim()
          echo "ec2-imdsv2-check Compliance Status: ${ec2Status}"
          if (ec2Status != 'COMPLIANT') {
            echo "Fetching non-compliant EC2 instances..."
            def nonCompliantResources = sh(
              script: "aws configservice get-resource-config-history --resource-type AWS::EC2::Instance --region $AWS_REGION --query 'configurationItems[?configuration.imdsSupport != `required`].resourceId' --output text",
              returnStdout: true
            ).trim().split()
            
            for (instanceId in nonCompliantResources) {
              echo "Remediating EC2 instance ${instanceId} to enforce IMDSv2..."
              // Example remediation CLI (adjust if using Terraform or Lambda)
              sh "aws ec2 modify-instance-metadata-options --instance-id ${instanceId} --http-tokens required --region $AWS_REGION"
            }
          }
        }
      }
    }
    stage('Remediate IAM No Inline Policies') {
      steps {
        script {
          def iamStatus = sh(
            script: "aws configservice describe-compliance-by-config-rule --config-rule-names iam-no-inline-policy-check --region $AWS_REGION --query 'ComplianceByConfigRules[0].Compliance.ComplianceType' --output text",
            returnStdout: true
          ).trim()
          echo "iam-no-inline-policy-check Compliance Status: ${iamStatus}"
          if (iamStatus != 'COMPLIANT') {
            echo "Fetching users with inline policies..."
            def users = sh(
              script: "aws iam list-users --query 'Users[].UserName' --output text",
              returnStdout: true
            ).trim().split()
            
            for (user in users) {
              def inlinePolicies = sh(
                script: "aws iam list-user-policies --user-name ${user} --query 'PolicyNames' --output text",
                returnStdout: true
              ).trim()
              
              if (inlinePolicies) {
                for (policy in inlinePolicies.split()) {
                  echo "Detaching inline policy ${policy} from user ${user}..."
                  // Example removal of inline policy
                  sh "aws iam delete-user-policy --user-name ${user} --policy-name ${policy}"
                }
              }
            }
          }
        }
      }
    }
    stage('Remediate S3 Versioning and Lifecycle') {
      steps {
        script {
          def s3Status = sh(
            script: "aws configservice describe-compliance-by-config-rule --config-rule-names s3-version-lifecycle-policy-check --region $AWS_REGION --query 'ComplianceByConfigRules[0].Compliance.ComplianceType' --output text",
            returnStdout: true
          ).trim()
          echo "s3-version-lifecycle-policy-check Compliance Status: ${s3Status}"
          if (s3Status != 'COMPLIANT') {
            echo "Fetching non-compliant S3 buckets..."
            // Placeholder: Identify buckets missing versioning or lifecycle policies
            def buckets = sh(
              script: "aws s3api list-buckets --query 'Buckets[].Name' --output text",
              returnStdout: true
            ).trim().split()
            
            for (bucket in buckets) {
              // Check if versioning is enabled
              def versioning = sh(
                script: "aws s3api get-bucket-versioning --bucket ${bucket} --query 'Status' --output text",
                returnStdout: true
              ).trim()
              
              if (versioning != 'Enabled') {
                echo "Enabling versioning on bucket ${bucket}..."
                sh "aws s3api put-bucket-versioning --bucket ${bucket} --versioning-configuration Status=Enabled"
              }
              
              // Check lifecycle configuration (simplified check)
              def lifecycle = sh(
                script: "aws s3api get-bucket-lifecycle-configuration --bucket ${bucket} --region $AWS_REGION || echo 'None'",
                returnStdout: true
              ).trim()
              
              if (lifecycle == 'None') {
                echo "Adding lifecycle policy to bucket ${bucket}..."
                def lifecyclePolicy = '''{
                  "Rules": [{
                    "ID": "ExpireOldVersions",
                    "Status": "Enabled",
                    "NoncurrentVersionExpiration": {"NoncurrentDays": 30}
                  }]
                }'''
                writeFile file: 'lifecycle.json', text: lifecyclePolicy
                sh "aws s3api put-bucket-lifecycle-configuration --bucket ${bucket} --lifecycle-configuration file://lifecycle.json"
              }
            }
          }
        }
      }
    }
  }
}
