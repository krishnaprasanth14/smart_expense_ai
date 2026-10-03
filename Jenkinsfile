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
                echo 'Running Flutter analysis, tests and Docker build'
                bat 'docker build -t smart-expense-ai-web:jenkins .'
            }
        }

        stage('Trivy Security Scan') {
            steps {
                echo 'Scanning Docker image for HIGH and CRITICAL vulnerabilities'
                bat 'trivy image --exit-code 1 --severity HIGH,CRITICAL smart-expense-ai-web:jenkins'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying Smart Expense AI using Docker Compose'
                bat 'docker compose down'
                bat 'docker compose up -d'
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Checking Docker Compose deployment'
                bat 'docker compose ps'
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

        always {
            echo 'Jenkins pipeline execution completed.'
        }
    }
}