pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out Smart Expense AI source code'
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Smart Expense AI Docker image'
                bat 'docker build -t smart-expense-ai-web:jenkins .'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying Smart Expense AI container'

                bat 'docker stop smart-expense-ai-jenkins 2>NUL || exit /b 0'
                bat 'docker rm smart-expense-ai-jenkins 2>NUL || exit /b 0'

                bat 'docker run -d -p 8082:80 --name smart-expense-ai-jenkins smart-expense-ai-web:jenkins'
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Checking deployed container'
                bat 'docker ps --filter "name=smart-expense-ai-jenkins"'
            }
        }
    }

    post {
        success {
            echo 'Smart Expense AI deployment completed successfully!'
        }

        failure {
            echo 'Smart Expense AI deployment failed.'
        }
    }
}
