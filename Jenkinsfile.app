pipeline {

  agent { label 'app-server-agent' }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    APP_NAME = "myapp"
    VERSION  = readFile('app/version.txt').trim()
    NETWORK  = "app-net"
    BLUE     = "myapp-blue"
    GREEN    = "myapp-green"
    BLUE_PORT  = "8081"
    GREEN_PORT = "8082"
  }

  stages {


    stage( 'Ensure nginx via Ansible' ) {
      steps {
        sh '''
           cd ansible
           ansible-playbook playbooks/infra.yml
        '''
      }
    }

    stage('Ensure Docker Network') {
      steps {
        sh '''
          docker network inspect ${NETWORK} >/dev/null 2>&1 || \
          docker network create ${NETWORK}
        '''
      }
    }

    stage('Detect Active Color') {
      steps {
        script {
          def active = sh(
            script: "docker ps --format '{{.Names}}' | grep -E 'myapp-blue|green' || true",
            returnStdout: true
          ).trim()

          if (active.contains("blue")) {
            env.ACTIVE_COLOR = "blue"
            env.NEW_COLOR = "green"
            env.NEW_PORT = "8082"
          } else {
            env.ACTIVE_COLOR = "green"
            env.NEW_COLOR = "blue"
            env.NEW_PORT = "8081"
          }

          echo "Active: ${env.ACTIVE_COLOR}"
          echo "Deploying: ${env.NEW_COLOR}"
          echo "New Port: ${env.NEW_PORT}"
        }
      }
    }

    stage('Build Image') {
      steps {
        sh '''
          docker build \
            -t ${APP_NAME}:${VERSION} \
            -t ${APP_NAME}:latest \
            app/
        '''
      }
    }

    stage('Deploy New Version') {
      steps {
        sh '''
          docker rm -f myapp-${env.NEW_COLOR} || true

          docker run -d \
            --name myapp-${env.NEW_COLOR} \
            --network app-net \
            -p ${env.NEW_PORT}:8080 \
            myapp:${IMAGE_TAG}
        '''
      }
    }

 
   stage('Health Check') {
    steps {
        script {
            echo "Starting health check for ${env.NEW_COLOR} on http://localhost:${env.NEW_PORT}"

            for (int i = 1; i <= 10; i++) {
                def status = sh(
                    script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:${env.NEW_PORT} || true",
                    returnStdout: true
                ).trim()

                if (status == "200") {
                    echo "Application is healthy ✅"
                    return
                }

                echo "Attempt ${i}/10 failed (HTTP ${status}). Retrying in 3s..."
                sleep 3
            }

            error "Application failed health check after 10 attempts"
        }
    }
}




   stage('Switch Traffic') {
      steps {
        script {
          def workspaceDir = pwd()

          sh """
            mkdir -p "${workspaceDir}/nginx/conf.d"

            sed "s/{{ACTIVE_COLOR}}/${APP_NAME}-${NEW}/" \
              "${workspaceDir}/nginx/template/upstream.conf.tpl" \
              > "${workspaceDir}/nginx/conf.d/upstream.conf"

            docker exec nginx nginx -s reload
          """
        }
      }
    }

    stage('Cleanup Old Version') {
      steps {
        sh '''
          docker rm -f ${APP_NAME}-${ACTIVE} || true
        '''
      }
    }

  }

  post {
    failure {
      sh '''
        echo "Deployment failed. Rolling back..."
        docker rm -f ${APP_NAME}-${NEW} || true
      '''
    }

    success {
      echo "Deployment successful 🚀"
    }
  }
}

