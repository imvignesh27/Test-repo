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
        stage('Compliance Checks') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS'
                ]]) {
                    script {
                        // IAM Compliance Check: List policies and confirm Admin policy details
                        echo "Checking IAM policies..."
                        sh '''
                            aws iam list-policies --scope Local
                            aws iam get-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
                        '''

                        // S3 Compliance Check: Policy, ACL, and encryption presence
                        echo "Checking S3 buckets..."
                        sh '''
                            for bucket in $(aws s3api list-buckets --query "Buckets[].Name" --output text); do
                              aws s3api get-bucket-policy --bucket "$bucket" || echo "No policy found for $bucket."
                              aws s3api get-bucket-acl --bucket "$bucket" || echo "No ACL found for $bucket."
                              aws s3api get-bucket-encryption --bucket "$bucket" || echo "No encryption found for $bucket."
                            done
                        '''

                        // EC2 Compliance Check: IMDSv2 on all instances and default security groups
                        echo "Checking EC2 instances..."
                        sh '''
                            aws ec2 describe-instances --query "Reservations[*].Instances[*].MetadataOptions"
                            aws ec2 describe-security-groups --query "SecurityGroups[?GroupName==`default`]"
                        '''
                    }
                }
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
                    sh "terraform plan -out=tfplan -var-file=terraform.tfvars"
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
