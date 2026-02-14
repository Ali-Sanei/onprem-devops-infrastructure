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
        ansiblePlaybook (
	  playbook: 'ansible/playbooks/infra.yml',
          inventory: 'ansible/inventory/hosts.ini',
	  installation: 'ansible',
          credentialsId: '',
          extras: '',
          ansibleCfg: 'ansible/ansible.cfg'
	  
        )
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
            script: "docker ps --format '{{.Names}}' | grep -E '${BLUE}|${GREEN}' || true",
            returnStdout: true
          ).trim()

          if (active.contains("blue")) {
            env.ACTIVE = "blue"
            env.NEW = "green"
            env.PORT = GREEN_PORT
          } else {
            env.ACTIVE = "green"
            env.NEW = "blue"
            env.PORT = BLUE_PORT
          }

          echo "Active: ${env.ACTIVE}"
          echo "Deploying: ${env.NEW}"
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
          docker rm -f ${APP_NAME}-${NEW} || true

          docker run -d \
            --name ${APP_NAME}-${NEW} \
            --network ${NETWORK} \
            -p ${PORT}:8080 \
            ${APP_NAME}:${VERSION}
        '''
      }
    }

    stage('Health Check') {
      steps {
        sh '''
          echo "Waiting for app to start..."
          sleep 5

          for i in {1..10}; do
            if curl -fs http://${APP_NAME}-${NEW}:8080; then
              echo "Health check passed"
              exit 0
            fi
            echo "Retry $i..."
            sleep 3
          done

          echo "Health check failed!"
          exit 1
        '''
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

