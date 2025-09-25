pipeline {
    agent any
    stages {
        stage('Run Shell Script') {
            steps {
                // Example: Execute a command inline
                sh 'echo "Hello from Jenkins!"'

                // Example: Execute a script from the repository
                // Ensure the script has execute permissions (e.g., chmod +x my_script.sh)
                sh './shG.sh'
            }
        }
    }
}