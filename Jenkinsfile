pipeline {
  agent any

  environment {
    ANSIBLE_CONFIG = "${WORKSPACE}/ansible/ansible.cfg"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t my-nginx:latest app/
        '''
      }
    }

    stage('Deploy with Ansible') {
      steps {
        sshagent(['devops-ssh']) {
          sh '''
            ansible-playbook ansible/playbooks/site.yml --limit app
          '''
        }
      }
    }
  }
}

