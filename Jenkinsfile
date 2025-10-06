pipeline {
    agent any // Specifies that the pipeline can run on any available agent

    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/your-username/your-repo.git' // Replace with your repository URL
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package' // Example for a Maven project
                // Or for a Node.js project: sh 'npm install'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test' // Example for a Maven project
                // Or for a Node.js project: sh 'npm test'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                // Add deployment commands here, e.g., to a server or cloud platform
                // sh 'scp target/your-app.jar user@your-server:/opt/your-app/'
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}