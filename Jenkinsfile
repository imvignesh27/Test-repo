pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
    }
    parameters {
        booleanParam(name: 'APPLY_TF', defaultValue: false, description: 'Set to true to apply Terraform changes')
        booleanParam(name: 'APPLY_DESTROY', defaultValue: false, description: 'Set to true to destroy Terraform-managed infrastructure')
    }
    stages {
        // ... previous stages ...

        stage('Terraform Apply') {
            when {
                expression { return params.APPLY_TF }
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

        stage('Detect AWS Config Rules') {
            when {
                expression { return params.APPLY_TF }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS'
                ]]) {
                    script {
                        def rules = ['ec2-imdsv2-check', 'iam-user-no-policies-check', 's3-version-lifecycle-policy-check']
                        for (rule in rules) {
                            def status = sh(
                                script: "aws configservice describe-config-rules --config-rule-names ${rule} --region $AWS_DEFAULT_REGION --query 'ConfigRules[0].ConfigRuleState' --output text",
                                returnStdout: true
                            ).trim()
                            echo "Config Rule ${rule} is in state: ${status}"
                        }
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return params.APPLY_DESTROY }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS'
                ]]) {
                    sh 'terraform destroy -auto-approve -var-file=terraform.tfvars'
                }
            }
        }

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
    }
    post {
        success {
            echo 'Terraform pipeline executed successfully!'
        }
        failure {
            echo 'Build failed. Check logs for details.'
        }
        always {
            archiveArtifacts artifacts: '**/*.tf', allowEmptyArchive: true
            cleanWs()
        }
    }
}
