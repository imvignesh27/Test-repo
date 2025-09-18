pipeline {
  agent any
  environment {
    AWS_ACCESS_KEY_ID     = credentials('AWS')
    AWS_SECRET_ACCESS_KEY = credentials('AWS')
    AWS_DEFAULT_REGION    = 'ap-south-1'
  }
  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      }
    }
    stage('Terraform Init & Apply') {
      steps {
        sh 'terraform init'
        sh 'terraform apply -auto-approve'
      }
    }
    stage('Trigger AWS Config Compliance Evaluation') {
      steps {
        // Manually trigger Config rule evaluation (optional - Config continuously runs evaluations)
        sh '''
          aws configservice start-config-rules-evaluation --config-rule-names s3-version-lifecycle-policy-check
        '''
      }
    }
    stage('Check Compliance Status and Trigger Auto Remediation') {
      steps {
        script {
          def compliance = sh (
            script: '''
              aws configservice describe-compliance-by-config-rule \
                --config-rule-name s3-version-lifecycle-policy-check \
                --query "ComplianceByConfigRules[0].ComplianceType" \
                --output text
            ''',
            returnStdout: true
          ).trim()

          if (compliance != 'COMPLIANT') {
            echo "Bucket is non-compliant, triggering remediation..."
            // Trigger remediation execution on non-compliant resource
            def bucket_name = sh (
              script: '''
                aws s3api list-buckets --query "Buckets[0].Name" --output text
              ''',
              returnStdout: true
            ).trim()

            sh """
              aws ssm start-automation-execution \
                --document-name AWS-UpdateS3BucketVersioning \
                --parameters BucketName=${bucket_name},VersioningConfiguration=Enabled
            """
            error("Compliance violation found and remediation triggered. Please verify.")
          } else {
            echo "Bucket is CIS compliant."
          }
        }
      }
    }
  }
  post {
    failure {
      echo "Pipeline failed due to compliance issues or errors."
    }
  }
}
