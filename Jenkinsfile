pipeline {
    agent any

    triggers {
        githubPush()
    }

    tools {
        maven 'maven'
    }

    environment {
        PATH = "/usr/local/bin:/opt/homebrew/bin:${env.PATH}"

        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_REPO = 'menyar35160/student-management'
        IMAGE_TAG = "${BUILD_NUMBER}"

        K8S_NAMESPACE = 'devops'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/benghorbelmenyar/StudentsManagement-DevOps.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    echo "=== Listing target directory ==="
                    ls -la target/
                    echo "=== Building Docker image ==="
                    docker build --no-cache -t ${DOCKERHUB_REPO}:${IMAGE_TAG} .
                    docker tag ${DOCKERHUB_REPO}:${IMAGE_TAG} ${DOCKERHUB_REPO}:latest
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh """
                    echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}
                    docker push ${DOCKERHUB_REPO}:latest
                    docker logout
                """
            }
        }

        stage('Setup Kubernetes Config') {
            steps {
                sh '''
                    # Vérifier que Minikube est démarré
                    minikube status || minikube start
                    
                    # Configurer kubectl pour utiliser Minikube
                    minikube update-context
                    
                    # Utiliser le contexte minikube directement
                    kubectl config use-context minikube
                    
                    # Vérifier la connexion
                    kubectl cluster-info
                    kubectl get nodes
                '''
            }
        }

        stage('Create Namespace') {
            steps {
                sh '''
                    kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                    kubectl get namespace ${K8S_NAMESPACE}
                '''
            }
        }

        stage('Deploy MySQL to Kubernetes') {
            steps {
                sh """
                    kubectl apply -f k8s/mysql-deployment.yaml -n ${K8S_NAMESPACE}

                    kubectl wait --for=condition=ready pod -l app=mysql -n ${K8S_NAMESPACE} --timeout=300s || {
                        kubectl get pods -n ${K8S_NAMESPACE}
                        kubectl describe pod -l app=mysql -n ${K8S_NAMESPACE}
                        exit 1
                    }
                """
            }
        }

        stage('Deploy App to Kubernetes') {
            steps {
                sh """
                    kubectl apply -f k8s/spring-deployment.yaml -n ${K8S_NAMESPACE}

                    kubectl set image deployment/student-management \
                        student-management=${DOCKERHUB_REPO}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE}

                    kubectl rollout status deployment/student-management -n ${K8S_NAMESPACE} --timeout=300s
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    kubectl get pods -n ${K8S_NAMESPACE} -o wide
                    kubectl get svc -n ${K8S_NAMESPACE}
                    kubectl get deployments -n ${K8S_NAMESPACE}
                    kubectl logs -l app=student-management -n ${K8S_NAMESPACE} --tail=50 || true
                """
            }
        }

        stage('Get Service URL') {
            steps {
                sh """
                    MINIKUBE_IP=\$(minikube ip)
                    echo "==============================================="
                    echo "Application URL: http://\${MINIKUBE_IP}:30080"
                    echo "==============================================="
                """
            }
        }

        stage('Cleanup') {
            steps {
                sh 'docker system prune -f || true'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
            echo "Docker Image: ${DOCKERHUB_REPO}:${IMAGE_TAG}"
            echo "Kubernetes Namespace: ${K8S_NAMESPACE}"
        }

        failure {
            echo "❌ Pipeline failed! Check the logs above for details."
        }
    }
}