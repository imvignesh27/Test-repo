pipeline {
  agent any
  environment {
    AWS_REGION = 'ap-south-1'
  }
  parameters {
    booleanParam(name: 'APPLY_TF', defaultValue: false, description: 'Set true to apply Terraform changes')
    booleanParam(name: 'APPLY_REMEDIATION', defaultValue: false, description: 'Set true to apply AWS Config remediation')
  }
  stages {
    // Checkout, Terraform Init, Plan, and Apply stages remain unchanged

    stage('Detect and Remediate EC2 IMDSv2') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          script {
            def ec2Status = sh(
              script: "aws configservice describe-compliance-by-config-rule --config-rule-names ec2-imdsv2-check --region $AWS_REGION --query ComplianceByConfigRules[0].Compliance.ComplianceType --output text",
              returnStdout: true
            ).trim()
            echo "ec2-imdsv2-check Status: ${ec2Status}"
            if (ec2Status != 'COMPLIANT') {
              def nonCompliantInstances = sh(
                script: "aws configservice get-compliance-details-by-config-rule --config-rule-name ec2-imdsv2-check --compliance-types NON_COMPLIANT --region $AWS_REGION --query 'EvaluationResults[].EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId' --output text",
                returnStdout: true
              ).trim().split()

              for (instanceId in nonCompliantInstances) {
                echo "Enforcing IMDSv2 on EC2 instance ${instanceId}..."
                sh "aws ec2 modify-instance-metadata-options --instance-id ${instanceId} --http-tokens required --region $AWS_REGION"
              }
            }
          }
        }
      }
    }

    stage('Detect and Remediate IAM User No Policies') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          script {
            def iamStatus = sh(
              script: "aws configservice describe-compliance-by-config-rule --config-rule-names iam-user-no-policies-check --region $AWS_REGION --query ComplianceByConfigRules[0].Compliance.ComplianceType --output text",
              returnStdout: true
            ).trim()
            echo "iam-user-no-policies-check Status: ${iamStatus}"
            if (iamStatus != 'COMPLIANT') {
              def nonCompliantUsers = sh(
                script: "aws configservice get-compliance-details-by-config-rule --config-rule-name iam-user-no-policies-check --compliance-types NON_COMPLIANT --region $AWS_REGION --query 'EvaluationResults[].EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId' --output text",
                returnStdout: true
              ).trim().split()

              for (userName in nonCompliantUsers) {
                echo "Attaching ReadOnlyAccess policy to IAM user ${userName}..."
                sh "aws iam attach-user-policy --user-name ${userName} --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess"
              }
            }
          }
        }
      }
    }

    stage('Detect and Remediate S3 Version and Lifecycle Policy') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          script {
            def s3Status = sh(
              script: "aws configservice describe-compliance-by-config-rule --config-rule-names s3-version-lifecycle-policy-check --region $AWS_REGION --query ComplianceByConfigRules[0].Compliance.ComplianceType --output text",
              returnStdout: true
            ).trim()
            echo "s3-version-lifecycle-policy-check Status: ${s3Status}"
            if (s3Status != 'COMPLIANT') {
              def buckets = sh(
                script: "aws configservice get-compliance-details-by-config-rule --config-rule-name s3-version-lifecycle-policy-check --compliance-types NON_COMPLIANT --region $AWS_REGION --query 'EvaluationResults[].EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId' --output text",
                returnStdout: true
              ).trim().split()

              for (bucket in buckets) {
                try {
                  sh "aws s3api head-bucket --bucket ${bucket} --region $AWS_REGION"
                  echo "Enabling versioning on S3 bucket ${bucket}..."
                  sh "aws s3api put-bucket-versioning --bucket ${bucket} --versioning-configuration Status=Enabled"

                  echo "Adding lifecycle policy to S3 bucket ${bucket}..."
                  def lifecyclePolicy = '''{
                    "Rules": [{
                      "ID": "ExpireOldVersions",
                      "Status": "Enabled",
                      "NoncurrentVersionExpiration": { "NoncurrentDays": 30 }
                    }]
                  }'''
                  writeFile file: 'lifecycle.json', text: lifecyclePolicy
                  sh "aws s3api put-bucket-lifecycle-configuration --bucket ${bucket} --lifecycle-configuration file://lifecycle.json"
                } catch (Exception e) {
                  echo "Bucket ${bucket} does not exist or is inaccessible. Skipping remediation."
                }
              }
            }
          }
        }
      }
    }
  }
  post {
    success {
      echo 'Pipeline completed successfully.'
    }
    failure {
      echo 'Pipeline failed. Please review logs.'
    }
    always {
      archiveArtifacts artifacts: '**/*.tf', allowEmptyArchive: true
    }
  }
}
