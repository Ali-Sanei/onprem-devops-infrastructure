pipeline {
  agent { label 'app-server-agent' }

  environment {
    APP_NAME = "myapp"
    VERSION = readFile('app/version.txt').trim()
    BLUE_PORT = "8081"
    GREEN_PORT = "8082"
  }

  stages {

    stage('Detect Active Color') {
      steps {
        sh '''
          if docker ps --format '{{.Names}}' | grep -q myapp-blue; then
            echo blue > /tmp/active_color
          else
            echo green > /tmp/active_color
          fi
        '''
      }
    }

    stage('Build Image') {
      steps {
        sh "docker build -t ${APP_NAME}:${VERSION} app/"
      }
    }

    stage('Deploy New Color') {
      steps {
        script {
          def active = sh(script: "cat /tmp/active_color", returnStdout: true).trim()
          env.NEW = (active == 'blue') ? 'green' : 'blue'
          env.PORT = (env.NEW == 'blue') ? BLUE_PORT : GREEN_PORT
        }

        sh '''
          docker rm -f myapp-${NEW} || true
          docker run -d \
            --name myapp-${NEW} \
            -p ${PORT}:8080 \
            myapp:${VERSION}
        '''
      }
    }

    stage('Health Check') {
      steps {
        sh '''
          sleep 5
          docker exec myapp-${NEW} /app/health.sh
        '''
      }
    }

    stage('Switch Traffic') {
      steps {
        script {
          def workspaceDir = pwd()
          sh """
            mkdir -p "${workspaceDir}/nginx/conf.d"
            sed "s/{{ACTIVE_COLOR}}/myapp-${NEW}/" "${workspaceDir}/nginx/template/upstream.conf.tpl" > "${workspaceDir}/nginx/conf.d/upstream.conf"

            docker rm -f nginx || true
            docker run -d \
              --name nginx \
              -p 80:80 \
              -v "${workspaceDir}/nginx:/etc/nginx" \
              nginx
          """
        }
      }
    }

    stage('Cleanup Old Color') {
      steps {
        sh '''
          ACTIVE=$(cat /tmp/active_color)
          docker rm -f myapp-$ACTIVE || true
        '''
      }
    }

  }
}

