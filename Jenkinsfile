pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['deploy', 'rollback'], description: 'Select action to execute')
        string(name: 'VERSION', defaultValue: 'v1.0.0', description: 'Target version tag (e.g. v1.0.0)')
    }

    environment {
        AWS_ACCOUNT_ID     = '781493733610'
        AWS_REGION         = 'ap-southeast-2'
        ECR_REPO_NAME      = 'usea-first-appb'
        SWARM_MANAGER      = '172.31.47.60'
        SERVICE_NAME       = 'my_web_app'
        TELEGRAM_BOT_TOKEN = credentials('telegram-bot-token')
        TELEGRAM_CHAT_ID   = credentials('telegram-chat-id')
    }

    stages {
        stage('1. Determine Version & Action') {
            steps {
                script {
                    if (env.TAG_NAME) {
                        env.RELEASE_TAG = env.TAG_NAME
                        env.CURRENT_ACTION = 'deploy'
                    } else {
                        env.RELEASE_TAG = params.VERSION
                        env.CURRENT_ACTION = params.ACTION
                    }
                    echo "Executing ${env.CURRENT_ACTION} for target version ${env.RELEASE_TAG}"
                }
            }
        }

        stage('2. Build & Push Image to ECR') {
            when {
                expression { env.CURRENT_ACTION == 'deploy' }
            }
            steps {
                script {
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    docker build -t ${ECR_REPO_NAME}:${RELEASE_TAG} .
                    docker tag ${ECR_REPO_NAME}:${RELEASE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${RELEASE_TAG}
                    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${RELEASE_TAG}
                    """
                }
            }
        }

        stage('3. Deploy or Rollback on Docker Swarm') {
            steps {
                sshagent(['swarm-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${SWARM_MANAGER} "
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        docker service update --image ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${RELEASE_TAG} --with-registry-auth ${SERVICE_NAME}
                    "
                    """
                }
            }
        }
    }

    post {
        success {
            script {
                def msg = "✅ *Jenkins Pipeline SUCCESS*%0A*Job:* ${env.JOB_NAME}%0A*Build:* %23${env.BUILD_NUMBER}%0A*Action:* ${env.CURRENT_ACTION}%0A*Version:* ${env.RELEASE_TAG}"
                sh "curl -s -X POST 'https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage' -d 'chat_id=${TELEGRAM_CHAT_ID}&text=${msg}&parse_mode=Markdown'"
            }
        }
        failure {
            script {
                def msg = "❌ *Jenkins Pipeline FAILED*%0A*Job:* ${env.JOB_NAME}%0A*Build:* %23${env.BUILD_NUMBER}%0A*Action:* ${env.CURRENT_ACTION}%0A*Version:* ${env.RELEASE_TAG}"
                sh "curl -s -X POST 'https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage' -d 'chat_id=${TELEGRAM_CHAT_ID}&text=${msg}&parse_mode=Markdown'"
            }
        }
    }
}