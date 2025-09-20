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
                    // This call uses terraform.tfvars to provide parameters for:
                    // - IAM user creation
                    // - S3 bucket creation
                    // - EC2 instance creation
                    sh "terraform plan -out=tfplan -var-file=terraform.tfvars"
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
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
    }
    post {
        success {
            echo 'Terraform pipeline executed successfully! IAM user, S3 bucket, and EC2 instance created.'
        }
        failure {
            echo 'Build failed. Please check logs for details.'
        }
        always {
            archiveArtifacts artifacts: '**/*.tf', allowEmptyArchive: true
        }
    }
}
