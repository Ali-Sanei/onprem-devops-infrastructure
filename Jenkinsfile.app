pipeline {
  agent {label 'app-server-agent'}

  environment {
    APP_NAME = "myapp"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Read Version') {
      steps {
        script {
          env.VERSION = readFile('app/version.txt').trim()
        }
      }
    }

    stage('Build Image') {
      steps {
        sh """
          docker build -t ${APP_NAME}:${VERSION} app
        """
      }
    }

    stage('Deploy') {
      steps {
        sh """
          docker rm -f ${APP_NAME} || true
          docker run -d --name ${APP_NAME} ${APP_NAME}:${VERSION}
        """
      }
    }
  }
}

