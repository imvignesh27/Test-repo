pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
    }
    parameters {
        booleanParam(name: 'APPLY_TF', defaultValue: false, description: 'Set to true to apply Terraform changes')
        booleanParam(name: 'APPLY_DESTROY', defaultValue: false, description: 'Set to true to destroy infrastructure')
    }
    stages {
        stage('Checkout SCM') {
            steps {
                git branch: 'main', url: 'https://github.com/imvignesh27/Test-repo'
            }
        }
        
        stage('Security Scan (Checkov)') {
            steps {
                script {
                    echo "--- Running CIS Benchmark Security Scan ---"                  
                    // Runs scan on the current directory. 
                    // Soft-fail is disabled (default) to break the build on failure.
                    // You can use --check to filter for specific CIS IDs
                    sh 'checkov -d . --framework terraform --quiet --output cli'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    sh 'terraform plan -out=tfplan -var-file=terraform.tfvars'
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { return params.APPLY_TF } }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { return params.APPLY_DESTROY } }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    sh 'terraform destroy -auto-approve -var-file=terraform.tfvars'
                }
            }
        }
    }
    
    post {
        always {
            // Optional: Archive the security report if generated as XML/JSON
            archiveArtifacts artifacts: '**/*.tf', allowEmptyArchive: true
            cleanWs()
        }
    }
}
