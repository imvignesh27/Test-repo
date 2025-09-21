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
                    sh '''
                        terraform plan -out=tfplan -var-file=terraform.tfvars
                        if [ $? -ne 0 ]; then
                          echo "Terraform plan failed"
                          exit 1
                        fi
                    '''
                }
            }
        }
        stage('Terraform Apply') {
            when {
                expression { return params.APPLY_TF }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS'
                ]]) {
                    sh '''
                        if [ -f tfplan ]; then
                            echo "Applying terraform using plan file"
                            terraform apply -auto-approve tfplan
                        else
                            echo "Plan file tfplan not found, applying directly with var-file"
                            terraform apply -auto-approve -var-file=terraform.tfvars
                        fi
                    '''
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
            echo 'Build failed. Please check logs for details.'
        }
        always {
            archiveArtifacts artifacts: '**/*.tf', allowEmptyArchive: true
            cleanWs()
        }
    }
}
