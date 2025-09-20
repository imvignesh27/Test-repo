pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
    }
    parameters {
        booleanParam(name: 'APPLY_TF', defaultValue: false, description: 'Set to true to apply Terraform changes')
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
                expression { return params.APPLY_TF == true }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS'
                ]]) {
                    sh 'terraform apply -auto-approve tfplan -var-file=terraform.tfvars'
                }
            }
        }
    }
    post {
        success {
            echo 'Terraform applied successfully!'
        }
        failure {
            echo 'Build failed. Check logs for details.'
        }
        always {
            archiveArtifacts artifacts: '**/*.tf', allowEmptyArchive: true
        }
    }
}
