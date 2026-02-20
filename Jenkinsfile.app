pipeline {

  agent { label 'app-server-agent' }

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 15, unit: 'MINUTES')
  }

  environment {
    APP_NAME    = "myapp"
    VERSION     = readFile('app/version.txt').trim()
    NETWORK     = "app-net"
    BLUE        = "myapp-blue"
    GREEN       = "myapp-green"
    BLUE_PORT   = "8081"
    GREEN_PORT  = "8082"
    DOCKER_IMAGE = "allliiisaaannneiii/myapp"
  }

  stages {

    stage('Ensure nginx via Ansible') {
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
            script: "docker ps --format '{{.Names}}' | grep -E 'myapp-blue|myapp-green' || true",
            returnStdout: true
          ).trim()

          if (active.contains("blue")) {
            env.ACTIVE_COLOR = "blue"
            env.NEW_COLOR    = "green"
            env.NEW_PORT     = "${GREEN_PORT}"
          } else {
            env.ACTIVE_COLOR = "green"
            env.NEW_COLOR    = "blue"
            env.NEW_PORT     = "${BLUE_PORT}"
          }

          echo "Active: ${env.ACTIVE_COLOR}"
          echo "Deploying: ${env.NEW_COLOR}"
          echo "New Port: ${env.NEW_PORT}"
        }
      }
    }

    stage('Build Image') {
      steps {
        retry(3){
	  script {
	    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
         
	    sh '''
              docker build \
                -t ${APP_NAME}:${GIT_SHA} \
                -t ${APP_NAME}:latest \
                app/
            '''
	  }
        }
      }
    }
    
    stage ('Push to Docker Hub') {
      steps {
	withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
	  sh '''
	    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin 
	    docker tag ${APP_NAME}:${GIT_SHA} ${DOCKER_IMAGE}:${GIT_SHA}
            docker tag ${APP_NAME}:${GIT_SHA} ${DOCKER_IMAGE}:latest

            docker push ${DOCKER_IMAGE}:${GIT_SHA}
            docker push ${DOCKER_IMAGE}:latest
          '''
        }
      }
    }
    
    stage('Deploy New Version') {
      when {
        anyOf {
          branch 'develop'
          branch 'main'
        }
      }

      steps {

        script {
      
          if (env.BRANCH_NAME == 'develop') {
            env.NEW_PORT = "8082"
          } else {
            env.NEW_PORT = "8081"
          }

          echo "Deploying on port ${env.NEW_PORT}"
        }

        sh '''#!/bin/bash
          set -e

          echo "Pulling image: ${DOCKER_IMAGE}:${GIT_SHA}"
          docker pull ${DOCKER_IMAGE}:${GIT_SHA}

          echo "Removing old container if exists..."
          docker rm -f ${APP_NAME}-${NEW_COLOR} 2>/dev/null || true

          echo "Starting new container..."
          docker run -d \
            --name ${APP_NAME}-${NEW_COLOR} \
            --network ${NETWORK} \
            -p ${NEW_PORT}:8080 \
            --memory="128m" \
            --cpus="0.5" \
            --restart=always \
            ${DOCKER_IMAGE}:${GIT_SHA}

          echo "Container ${APP_NAME}-${NEW_COLOR} started on port ${NEW_PORT}"
        '''
      }
    }
    stage('Health Check') {
      steps {
        script {
          echo "Starting health check for ${NEW_COLOR} on http://localhost:${NEW_PORT}"

          def status = sh(
            script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:${NEW_PORT}",
             returnStdout: true).trim()

          if (status == "200") {
            echo "Application is healthy ✅"
          } else {
            echo "Health check failed ❌"
            echo "Starting rollback..."

            sh "docker rm -f myapp-${NEW_COLOR}"

            withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
              sh '''
               curl -X POST -H "Content-type: application/json" \
               --data "{\"text\":\"🔁 Deployment Failed - Rolled Back\nProject: $JOB_NAME\nBuild: #$BUILD_NUMBER\"}" \
               "$SLACK_URL"
               '''
            }

            error("Deployment failed. Rolled back to ${ACTIVE_COLOR}")
          }
        }
      }
    }

    stage('Production Approve') {
      when {
        branch 'main'
      }
      steps {
        timeout(time: 2, unit: 'MINUTES') {
          input message: "Deploy to PRODUCTION?", ok: "Deploy"
        }
      }

    }
    stage('Switch Traffic') {
      steps {
        script {
          def workspaceDir = pwd()

          sh """
            mkdir -p "${workspaceDir}/nginx/conf.d"

            sed "s/{{ACTIVE_COLOR}}/${NEW_COLOR}/" \
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
          docker rm -f ${APP_NAME}-${ACTIVE_COLOR} || true
        '''
      }
    }

  }



  Ali sanei, [2/20/26 9:11 PM]
echo "Removing old container if exists..."
          docker rm -f ${APP_NAME}-${NEW_COLOR} 2>/dev/null  true

          echo "Starting new container..."
          docker run -d \
            --name ${APP_NAME}-${NEW_COLOR} \
            --network ${NETWORK} \
            -p ${NEW_PORT}:8080 \
            --memory="128m" \
            --cpus="0.5" \
            --restart=always \
            ${DOCKER_IMAGE}:${GIT_SHA}

          echo "Container ${APP_NAME}-${NEW_COLOR} started on port ${NEW_PORT}"
        '''
      }
    }
    stage('Health Check') {
      steps {
        script {
          echo "Starting health check for ${NEW_COLOR} on http://localhost:${NEW_PORT}"

          def status = sh(
            script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:${NEW_PORT}",
             returnStdout: true).trim()

          if (status == "200") {
            echo "Application is healthy ✅"
          } else {
            echo "Health check failed ❌"
            echo "Starting rollback..."

            sh "docker rm -f myapp-${NEW_COLOR}"

            withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
              sh '''
               curl -X POST -H "Content-type: application/json" \
               --data "{\"text\":\"🔁 Deployment Failed - Rolled Back\nProject: $JOB_NAME\nBuild: #$BUILD_NUMBER\"}" \
               "$SLACK_URL"
               '''
            }

            error("Deployment failed. Rolled back to ${ACTIVE_COLOR}")
          }
        }
      }
    }

    stage('Production Approve') {
      when {
        branch 'main'
      }
      steps {
        timeout(time: 2, unit: 'MINUTES') {
          input message: "Deploy to PRODUCTION?", ok: "Deploy"
        }
      }

    }
    stage('Switch Traffic') {
      steps {
        script {
          def workspaceDir = pwd()

          sh """
            mkdir -p "${workspaceDir}/nginx/conf.d"

            sed "s/{{ACTIVE_COLOR}}/${NEW_COLOR}/" \
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
          docker rm -f ${APP_NAME}-${ACTIVE_COLOR}  true
        '''
      }
    }

  }



post {

  success {
    script {
      withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
        sh(returnStatus: true, script: '''
          payload=$(cat <<EOF
{
  "text": "✅ Deployment Successful\nProject: ${JOB_NAME}\nBuild: #${BUILD_NUMBER}"
}
EOF
)
          curl -s -o /dev/null -X POST \
            -H "Content-type: application/json" \
            --data "$payload" \
            "$SLACK_URL"
        ''')
      }
    }
  }

  failure {
    script {
      withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
        sh(returnStatus: true, script: '''
          payload=$(cat <<EOF
{
  "text": "❌ Deployment Failed\nProject: ${JOB_NAME}\nBuild: #${BUILD_NUMBER}"
}
EOF
)
          curl -s -o /dev/null -X POST \
            -H "Content-type: application/json" \
            --data "$payload" \
            "$SLACK_URL"
        ''')
      }
    }
  }

} 
}
