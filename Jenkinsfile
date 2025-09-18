pipeline {
  agent any

  environment {
    AWS_ACCESS_KEY_ID     = credentials('jenkins-aws-access-key-id')
    AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws-secret-access-key')
    AWS_DEFAULT_REGION    = 'ap-south-1'
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        sh 'terraform init'
      }
    }

    stage('Terraform Apply') {
      steps {
        // Use -auto-approve to skip manual approvals
        sh 'terraform apply -auto-approve'
      }
    }

    stage('Check S3 Compliance') {
      steps {
        script {
          def compliance = sh (
            script: '''
              aws configservice describe-compliance-by-config-rule \
                --config-rule-name s3-bucket-server-side-encryption-enabled \
                --query "ComplianceByConfigRules[0].ComplianceType" \
                --output text
            ''',
            returnStdout: true
          ).trim()

          if (compliance != 'COMPLIANT') {
            error("S3 Bucket is NOT CIS compliant. Compliance status: ${compliance}")
          } else {
            echo "S3 Bucket is CIS compliant."
          }
        }
      }
    }
  }

  post {
    failure {
      echo 'Build failed. Check logs for details.'
    }
    success {
      echo 'Build completed successfully and compliance checks passed.'
    }
  }
}
