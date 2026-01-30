pipeline {
  agent { label 'app-server-agent' }

  options {
    timestamps()
  }

  stages {

    stage('Checkout Source') {
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

    stage('Deploy Container') {
      steps {
        sh '''
          docker rm -f my-nginx || true
          docker run -d \
            --name my-nginx \
            -p 80:80 \
            my-nginx:latest
        '''
      }
    }
  }

  post {
    success {
      echo '✅ Deployment completed successfully'
    }
    failure {
      echo '❌ Deployment failed'
    }
  }
}

