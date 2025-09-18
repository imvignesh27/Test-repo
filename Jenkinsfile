pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        withAWS(credentials: 'AWS', region: "${AWS_DEFAULT_REGION}") {
          sh 'terraform init'
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        withAWS(credentials: 'AWS', region: "${AWS_DEFAULT_REGION}") {
          sh 'terraform apply -auto-approve'
        }
      }
    }

    stage('Check S3 Compliance') {
      steps {
        withAWS(credentials: 'jenkins-aws-access-key-id', region: "${AWS_DEFAULT_REGION}") {
          script {
            def compliance = sh(
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
