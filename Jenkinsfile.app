pipeline {
  agent { label 'app-server' }

  environment {
    APP_NAME = "myapp"
    VERSION = readFile('app/version.txt').trim()
    PREVIOUS_VERSION_FILE = "/tmp/myapp_prev_version"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Save Current Version') {
      steps {
        sh '''
          docker images --format "{{.Repository}}:{{.Tag}}" | grep ${APP_NAME} | head -n 1 | cut -d: -f2 > ${PREVIOUS_VERSION_FILE} || true
        '''
      }
    }

    stage('Build Image') {
      steps {
        sh """
          docker build -t ${APP_NAME}:${VERSION} app/
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

  post {
    failure {
      echo "❌ Deploy failed. Rolling back..."
      sh '''
        if [ -f ${PREVIOUS_VERSION_FILE} ]; then
          PREV_VERSION=$(cat ${PREVIOUS_VERSION_FILE})
          docker rm -f ${APP_NAME} || true
          docker run -d --name ${APP_NAME} ${APP_NAME}:${PREV_VERSION}
        fi
      '''
    }
  }
}

