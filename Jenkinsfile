pipeline {
    agent any

    tools {
        git 'Default'
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

    stages {
        stage('Clone Repository') {
            steps {
                git credentialsId: 'd9abfd48-9f03-4e56-b83b-370155ba4f60', url: 'https://github.com/gaurav-tikhile-CG/terraform-demo.git', branch: 'main'
            }
        }

        stage('Terraform Init') {
            steps {
                bat 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                bat 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            steps {
                input message: 'Approve Terraform Apply?'
                bat 'terraform apply -auto-approve'
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
    }
}
