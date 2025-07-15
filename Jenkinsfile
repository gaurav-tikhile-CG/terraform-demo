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
            defaultValue: 'https://github.com/CG-FS-ABL/dcx-fs-ahead-accelerator-infra',
            description: 'URL of the Git repository containing the Terraform code'
        )
        string(
            name: 'BRANCH',
            defaultValue: 'ahead-infra-initial-release',
            description: 'Git branch to use (e.g. develop, main)'
        )
        string(
            name: 'GIT_CREDS_ID',
            defaultValue: 'gaurav-tikhile-CG',
            description: 'Jenkins Credential ID used for Git access'
        )
        string(
            name: 'AWS_IAM_ROLE',
            defaultValue: 'JenkinsWorkloadAccountAccessRole',
            description: 'IAM role to assume in the AWS account for deployment'
        )
    }

    environment {
        DEPLOY_ENV     = "${params.ENVIRONMENT}"
        REGION         = "${params.REGION}"
        AWS_ACCOUNT_ID = "730335494494"
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
                    Custom Environment Variables:
                    DEPLOY_ENV     : ${env.DEPLOY_ENV}
                    REGION         : ${env.REGION}
                    AWS_ACCOUNT_ID : ${env.AWS_ACCOUNT_ID}
                    AWS_IAM_ROLE   : ${env.AWS_IAM_ROLE}
                    TF_ACTION      : ${env.TF_ACTION}
                    GIT_REPO_URL   : ${env.GIT_REPO_URL}
                    BRANCH         : ${env.BRANCH}
                    GIT_CREDS_ID   : ${env.GIT_CREDS_ID}

                    Jenkins Environment Variables:
                    JOB_NAME       : ${env.JOB_NAME}
                    BUILD_NUMBER   : ${env.BUILD_NUMBER}
                    GIT_COMMIT     : ${env.GIT_COMMIT}
                    GIT_BRANCH     : ${env.GIT_BRANCH}
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
                            withAWS(roleAccount: env.AWS_ACCOUNT_ID, role: env.AWS_IAM_ROLE, region: env.REGION) {
                                echo "Running terraform init with backend config for ${env.DEPLOY_ENV}"
                                sh "terraform init -backend-config=environments/${env.DEPLOY_ENV}/backend.config -reconfigure"
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
                                    sh "terraform plan -var-file=environments/${env.DEPLOY_ENV}/terraform.tfvars -var='region=${env.REGION}' -out=tfplan"
                                } else if (env.TF_ACTION == 'destroy') {
                                    echo "Planning to destroy resources..."
                                    sh "terraform plan -destroy -var-file=environments/${env.DEPLOY_ENV}/terraform.tfvars -var='region=${env.REGION}' -out=tfplan"
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
        success {
            echo "Terraform ${env.TF_ACTION} completed successfully for ${env.DEPLOY_ENV} in ${env.REGION}"
        }
        failure {
            echo "Terraform ${env.TF_ACTION} failed for ${env.DEPLOY_ENV} in ${env.REGION}"
        }
        aborted {
            echo "Terraform ${env.TF_ACTION} was aborted for ${env.DEPLOY_ENV}"
        }
        always {
            echo "Archiving tfplan.txt and cleaning up workspace"
            dir('terraform') {
                archiveArtifacts artifacts: 'tfplan.txt', allowEmptyArchive: true
            }
            cleanWs()
        }
    }
}
