pipeline {
  agent any

  environment {
    APP_NAME = "myapp"
    DOCKER_IMAGE = "myapp-image"
    NETWORK = "my-network"
  }

  stages {

    stage('Set Environment') {
      steps {
        script {
          if (env.BRANCH_NAME == 'develop') {
            env.NEW_PORT = "8082"
          } else {
            env.NEW_PORT = "8081"
          }

          env.NEW_COLOR = (env.NEW_PORT == "8081") ? "blue" : "green"
          env.ACTIVE_COLOR = (env.NEW_COLOR == "blue") ? "green" : "blue"
          env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

          echo "Deploying ${env.NEW_COLOR} on port ${env.NEW_PORT}"
        }
      }
    }

    stage('Build Image') {
      steps {
        sh "docker build -t ${DOCKER_IMAGE}:${GIT_SHA} ."
      }
    }

    stage('Deploy New Container') {
      steps {
        sh """
          echo "Removing old new-color container if exists..."
          docker rm -f ${APP_NAME}-${NEW_COLOR} || true

          echo "Starting new container..."
          docker run -d \
            --name ${APP_NAME}-${NEW_COLOR} \
            --network ${NETWORK} \
            -p ${NEW_PORT}:8080 \
            --memory="128m" \
            --cpus="0.5" \
            --restart=always \
            ${DOCKER_IMAGE}:${GIT_SHA}
        """
      }
    }

    stage('Health Check') {
      steps {
        script {
          sleep 5
          def status = sh(
            script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:${NEW_PORT}",
            returnStdout: true
          ).trim()

          if (status != "200") {
            echo "Health check failed ❌ Rolling back..."
            sh "docker rm -f ${APP_NAME}-${NEW_COLOR} || true"
            error("Deployment failed.")
          }

          echo "Application healthy ✅"
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
          sh """
            sed "s/{{ACTIVE_COLOR}}/${NEW_COLOR}/" \
              nginx/template/upstream.conf.tpl > nginx/conf.d/upstream.conf

            docker exec nginx nginx -s reload
          """
        }
      }
    }

    stage('Cleanup Old Version') {
      steps {
        sh "docker rm -f ${APP_NAME}-${ACTIVE_COLOR} || true"
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
