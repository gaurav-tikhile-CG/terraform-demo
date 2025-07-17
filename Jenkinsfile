pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'qa', 'prod'],
            description: 'Select the target environment (e.g. dev, qa, prod)'
        )
        choice(
            name: 'REGION',
            choices: ['us-east-2', 'us-west-2'],
            description: 'AWS Region to deploy into (Ohio or Oregon)'
        )
        choice(
            name: 'TF_ACTION',
            choices: ['apply', 'destroy'],
            description: 'Choose whether to apply or destroy the infrastructure'
        )
        string(
            name: 'GIT_REPO_URL',
            defaultValue: 'https://github.com/gaurav-tikhile-CG/terraform-demo.git',
            description: 'URL of the Git repository containing the Terraform code'
        )
        string(
            name: 'BRANCH',
            defaultValue: 'main',
            description: 'Git branch to use (e.g. develop, main)'
        )
        string(
            name: 'GIT_CREDS_ID',
            defaultValue: 'd9abfd48-9f03-4e56-b83b-370155ba4f60',
            description: 'Jenkins Credential ID used for Git access'
        )
        string(
            name: 'AWS_IAM_ROLE',
            defaultValue: 'arn:aws:iam::028343876427',
            description: 'IAM role to assume in the AWS account for deployment'
        )
    }

    environment {
        DEPLOY_ENV     = "${params.ENVIRONMENT}"
        REGION         = "${params.REGION}"
        AWS_ACCOUNT_ID = "028343876427"
        AWS_IAM_ROLE   = "${params.AWS_IAM_ROLE}"
        TF_ACTION      = "${params.TF_ACTION}"
        GIT_REPO_URL   = "${params.GIT_REPO_URL}"
        BRANCH         = "${params.BRANCH}"
        GIT_CREDS_ID   = "${params.GIT_CREDS_ID}"
    }

    stages {
        stage('Print Config Details') {
            steps {
                script {
                    echo """
                    Pipeline Configuration:
                    ─────────────────────────────
                    DEPLOY_ENV     : ${env.DEPLOY_ENV}
                    REGION         : ${env.REGION}
                    AWS_ACCOUNT_ID : ${env.AWS_ACCOUNT_ID}
                    AWS_IAM_ROLE   : ${env.AWS_IAM_ROLE}
                    TF_ACTION      : ${env.TF_ACTION}
                    GIT_REPO_URL   : ${env.GIT_REPO_URL}
                    BRANCH         : ${env.BRANCH}
                    GIT_CREDS_ID   : ${env.GIT_CREDS_ID}
                    """
                }
            }
        }

        stage('Code Checkout') {
            steps {
                script {
                    try {
                        git branch: params.BRANCH,
                            credentialsId: env.GIT_CREDS_ID,
                            url: env.GIT_REPO_URL
                        echo "Code checkout successful for branch '${params.BRANCH}'"
                    } catch (err) {
                        error "Code checkout failed: ${err.getMessage()}"
                    }
                }
            }
        }

        stage('Initialize Terraform') {
            steps {
                dir('terraform') {
                    script {
                        try {
                            withAWS(credentials: 'aws-creds', role: env.AWS_IAM_ROLE, roleAccount: env.AWS_ACCOUNT_ID, region: env.REGION) {
                            sh 'terraform init -reconfigure'
                            }
                            echo "Terraform init successful"
                        } catch (err) {
                            error "Terraform init failed: ${err.getMessage()}"
                        }
                    }
                }
            }
        }

        stage('Validate & Plan') {
            steps {
                withAWS(roleAccount: env.AWS_ACCOUNT_ID, role: env.AWS_IAM_ROLE, region: env.REGION) {
                    dir('terraform') {
                        script {
                            try {
                                echo "Running terraform validate..."
                                sh "terraform validate"
                                echo "Validation passed"

                                if (env.TF_ACTION == 'apply') {
                                    echo "Planning to apply resources..."
                                    sh "terraform plan -var='region=${env.REGION}' -out=tfplan"
                                } else if (env.TF_ACTION == 'destroy') {
                                    echo "Planning to destroy resources..."
                                    sh "terraform plan -destroy -var='region=${env.REGION}' -out=tfplan"
                                } else {
                                    error "Invalid TF_ACTION: ${env.TF_ACTION}"
                                }

                                sh "ls -lh tfplan*"
                                sh "terraform show -no-color tfplan > tfplan.txt"
                                echo "Terraform plan completed for ${env.DEPLOY_ENV}"
                            } catch (err) {
                                error "Terraform plan failed: ${err.getMessage()}"
                            }
                        }
                    }
                }
            }
        }

        stage('Apply Terraform Changes') {
            steps {
                dir('terraform') {
                    script {
                        try {
                            echo "Checking if tfplan exists before apply..."
                            sh "test -f tfplan || { echo 'tfplan file missing. Aborting.'; exit 1; }"

                            withAWS(roleAccount: env.AWS_ACCOUNT_ID, role: env.AWS_IAM_ROLE, region: env.REGION) {
                                echo "Running terraform apply..."
                                sh "terraform apply -input=false tfplan"
                            }
                            echo "Terraform apply successful"
                        } catch (err) {
                            error "Terraform apply failed: ${err.getMessage()}"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished"
        }
    }
}
