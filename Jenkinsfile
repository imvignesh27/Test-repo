pipeline {
  agent any
  stages {
    stage('Terraform Apply') {
      steps {
        sh 'terraform init'
        sh 'terraform apply -auto-approve'
      }
    }
    stage('Check S3 Compliance') {
      steps {
        sh '''
          compliance=$(aws configservice describe-compliance-by-config-rule \
            --config-rule-name S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED \
            --query "ComplianceByConfigRules[0].ComplianceType" \
            --output text)
          if [ "$compliance" != "COMPLIANT" ]; then
            echo "S3 Bucket is NOT CIS compliant!"
            exit 1
          else
            echo "S3 Bucket is CIS compliant!"
          fi
        '''
      }
    }
  }
}
