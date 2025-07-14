pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('d9abfd48-9f03-4e56-b83b-370155ba4f60')
        AWS_SECRET_ACCESS_KEY = credentials('d9abfd48-9f03-4e56-b83b-370155ba4f60')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }
    }
}
