pipeline {
    agent any

    triggers {
        pollSCM('H/5 * * * *')
    }

    parameters {
        choice(name: 'ACTION', choices: ['deploy', 'rollback'], description: 'Select action to execute')
        string(name: 'VERSION', defaultValue: 'v1.0.0', description: 'Target version tag (e.g. v1.0.0, v1.1.0, v1.2.0)')
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

        stage('2. Automated Lint & Smoke Test') {
            when {
                expression { env.CURRENT_ACTION == 'deploy' }
            }
            steps {
                script {
                    echo "Executing pre-deployment automated tests..."
                    sh """
                    # Step A: Validate static HTML file structure
                    if ! grep -q "USEA Student Portal" index.html; then
                        echo "TEST FAILED: 'USEA Student Portal' header not found in index.html"
                        exit 1
                    fi

                    # Step B: Build localized test container image
                    docker build -t test-app:${BUILD_NUMBER} .

                    # Step C: Spin up ephemeral test container
                    docker rm -f smoke-test-${BUILD_NUMBER} 2>/dev/null || true
                    docker run -d --name smoke-test-${BUILD_NUMBER} -p 8089:80 test-app:${BUILD_NUMBER}
                    sleep 3

                    # Step D: Execute automated curl health check probe
                    HTTP_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8089/)
                    docker rm -f smoke-test-${BUILD_NUMBER}
                    docker rmi test-app:${BUILD_NUMBER} || true

                    if [ "\${HTTP_STATUS}" -ne 200 ]; then
                        echo "TEST FAILED: Container probe returned HTTP status \${HTTP_STATUS} (expected 200)"
                        exit 1
                    fi

                    echo "✅ Automated Smoke Test PASSED: Container responded with HTTP 200 OK"
                    """
                }
            }
        }

        stage('3. Build & Push Image to ECR') {
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

        stage('4. Deploy or Rollback on Docker Swarm') {
            steps {
                sshagent(['swarm-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${SWARM_MANAGER} "
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        docker service update --image ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${RELEASE_TAG} --with-registry-auth ${SERVICE_NAME}
                        docker service ps ${SERVICE_NAME}
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
