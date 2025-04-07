pipeline {
    agent { label 'infra' }
    environment {
        AWS_ACCOUNT_ID       = '664955381775'
        AWS_REGION           = 'eu-west-1'
        ECR_REPO_URI         = '${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-app' 
    }
    stages {
        // CI Stages
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // stage('Build Docker Image') {
        //     steps {
        //         script {
        //             docker.build("${ECR_REPO_URI}:${APP_VERSION}")
        //         }
        //     }
        // }

        // stage('Push to ECR') {
        //     steps {
        //         script {
        //             docker.withRegistry('https://account-id.dkr.ecr.region.amazonaws.com', 'ecr:us-west-2:aws-credentials') {
        //                 docker.image("${ECR_REPO_URI}:${APP_VERSION}").push()
        //             }
        //         }
        //     }
        // }

        // CD Stages - Infrastructure
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init --reconfigure'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Confirm Apply') {
            steps {
                script {
                    def userInput = input(
                        id: 'userInput',
                        message: 'Apply Terraform changes?',
                        parameters: [
                            [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply changes?', name: 'apply']
                        ]
                    )
                    if (userInput) {
                        env.TF_APPLY = true
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { return env.TF_APPLY == 'true' } }
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                    script {
                        env.CLUSTER_NAME = sh(
                            script: 'terraform output -raw eks_cluster_name',
                            returnStdout: true
                        ).trim()
                        env.AWS_REGION = sh(
                            script: 'terraform output -raw aws_region',
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }

        stage('Install ALB Controller') {
            when { expression { return env.TF_APPLY == 'true' } }
            steps {
                dir('scripts') {
                    sh 'chmod +x install-alb-controller.sh'
                    sh """
                        ./install-alb-controller.sh \
                        ${env.CLUSTER_NAME} \
                        ${env.AWS_REGION}
                    """
                    // Verify installation
                    sh 'kubectl wait --for=condition=available deployment/aws-load-balancer-controller -n kube-system --timeout=300s'
                }
            }
        }

        // CD Stages - Application Deployment
        stage('Deploy Kubernetes Manifests') {
            when { expression { return env.TF_APPLY == 'true' } }
            steps {
                dir('kubernetes') {
                    sh """
                        kubectl apply -f namespace.yaml
                        kubectl apply -f deployment.yaml -n my-app
                        kubectl apply -f service.yaml -n my-app
                        kubectl apply -f ingress.yaml -n my-app
                    """
                }
            }
        }

        // Cleanup Stage
        stage('Terraform Destroy') {
            when { 
                expression { 
                    return env.DESTROY_INFRA == 'true' 
                } 
            }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }
}

// Helper function to get git commit hash
def gitHash() {
    return sh(
        script: 'git rev-parse --short HEAD',
        returnStdout: true
    ).trim()
}