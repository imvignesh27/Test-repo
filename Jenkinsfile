pipeline {
  agent any
  environment {
    AWS_REGION = 'ap-south-1'
  }
  parameters {
    booleanParam(name: 'APPLY_REMEDIATION', defaultValue: false, description: 'Set to true to apply remediation for AWS Config violations')
  }
  stages {
    stage('Checkout SCM') {
      steps {
        git branch: 'main',
            url: 'https://github.com/imvignesh27/Test-repo'
      }
    }
    stage('Terraform Init') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          sh 'terraform init'
        }
      }
    }
    stage('Terraform Plan') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          sh 'terraform plan -out=tfplan -var-file=terraform.tfvars'
        }
      }
    }
    stage('Terraform Apply') {
      when {
        expression { return params.APPLY_REMEDIATION }
      }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          sh 'terraform apply -auto-approve tfplan'
        }
      }
    }
    stage('Remediate EC2 IMDSv2') {
      when {
        expression { return params.APPLY_REMEDIATION }
      }
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
            echo "ec2-imdsv2-check Compliance Status: ${ec2Status}"
            if (ec2Status != 'COMPLIANT') {
              echo "Fetching non-compliant EC2 instances..."
              def nonCompliantResources = sh(
                script: "aws configservice get-compliance-details-by-config-rule --config-rule-name ec2-imdsv2-check --compliance-types NON_COMPLIANT --region $AWS_REGION --query 'EvaluationResults[].EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId' --output text",
                returnStdout: true
              ).trim().split()
              
              for (instanceId in nonCompliantResources) {
                echo "Remediating EC2 instance ${instanceId} to enforce IMDSv2..."
                sh "aws ec2 modify-instance-metadata-options --instance-id ${instanceId} --http-tokens required --region $AWS_REGION"
              }
            }
          }
        }
      }
    }
    stage('Remediate IAM No Inline Policies') {
      when {
        expression { return params.APPLY_REMEDIATION }
      }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          script {
            def iamStatus = sh(
              script: "aws configservice describe-compliance-by-config-rule --config-rule-names iam-no-inline-policy-check --region $AWS_REGION --query ComplianceByConfigRules[0].Compliance.ComplianceType --output text",
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
                    echo "Deleting inline policy ${policy} from user ${user}..."
                    sh "aws iam delete-user-policy --user-name ${user} --policy-name ${policy}"
                  }
                }
              }
            }
          }
        }
      }
    }
    stage('Remediate S3 Versioning and Lifecycle') {
      when {
        expression { return params.APPLY_REMEDIATION }
      }
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
            echo "s3-version-lifecycle-policy-check Compliance Status: ${s3Status}"
            if (s3Status != 'COMPLIANT') {
              echo "Fetching all S3 buckets..."
              def buckets = sh(
                script: "aws s3api list-buckets --query 'Buckets[].Name' --output text",
                returnStdout: true
              ).trim().split()
              
              for (bucket in buckets) {
                def versioning = sh(
                  script: "aws s3api get-bucket-versioning --bucket ${bucket} --query 'Status' --output text || echo 'Disabled'",
                  returnStdout: true
                ).trim()
                
                if (versioning != 'Enabled') {
                  echo "Enabling versioning on bucket ${bucket}..."
                  sh "aws s3api put-bucket-versioning --bucket ${bucket} --versioning-configuration Status=Enabled"
                }
                
                def lifecycle
                try {
                  lifecycle = sh(
                    script: "aws s3api get-bucket-lifecycle-configuration --bucket ${bucket} --region $AWS_REGION",
                    returnStdout: true
                  ).trim()
                } catch (e) {
                  lifecycle = ''
                }
                
                if (!lifecycle) {
                  echo "Adding lifecycle configuration to bucket ${bucket}..."
                  writeFile file: 'lifecycle.json', text: '''{
                    "Rules": [{
                      "ID": "ExpireOldVersions",
                      "Status": "Enabled",
                      "NoncurrentVersionExpiration": { "NoncurrentDays": 30 }
                    }]
                  }'''
                  sh "aws s3api put-bucket-lifecycle-configuration --bucket ${bucket} --lifecycle-configuration file://lifecycle.json"
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
      echo 'Pipeline failed. Please check the logs.'
    }
  }
}
