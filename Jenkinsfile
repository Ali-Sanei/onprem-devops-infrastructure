pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/Ali-Sanei/onprem-devops-infrastructure.git'
      }
    }

    stage('Deploy with Ansible') {
      steps {
        sshagent(['devops']) {
          dir('ansible') {
            sh 'ansible-playbook playbooks/site.yml --limit app'
          }
        }
      }
    }
  }

  post {
    failure {
      echo 'Pipeline failed!'
    }
    success {
      echo 'Deployment successful!'
    }
  }
}

