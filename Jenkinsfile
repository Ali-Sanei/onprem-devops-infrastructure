pipeline {
    agent any

    environment {
        // مسیر به private key که توی Jenkins credentials اضافه کردی
        SSH_CREDENTIALS = 'devops-ssh'
        // مسیر کامل به ansible playbook روی CI server
        ANSIBLE_PLAYBOOK_PATH = '/home/jenkins/ansible/playbooks/site.yml'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git(
                    url: 'https://github.com/Ali-Sanei/onprem-devops-infrastructure.git',
                    branch: 'main'
                )
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t my-nginx:latest app/
                """
            }
        }

        stage('Deploy with Ansible') {
            steps {
                // استفاده از SSH agent برای اتصال بدون پسورد به app-server
                sshagent(credentials: [env.SSH_CREDENTIALS]) {
                    dir('/home/jenkins/ansible'){
                        sh 'ansible-playbook playbooks/site.yml --limit app'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline finished successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}

