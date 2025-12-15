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
        KUBECONFIG = "${WORKSPACE}/.kube/config"
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

        stage('Test') {
            steps {
                sh 'mvn test'
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
                    docker build -t ${DOCKERHUB_REPO}:${IMAGE_TAG} .
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
                    mkdir -p ${WORKSPACE}/.kube
                    minikube kubectl -- config view --flatten > ${WORKSPACE}/.kube/config
                    export KUBECONFIG=${WORKSPACE}/.kube/config
                    kubectl cluster-info
                    kubectl version --client
                '''
            }
        }

        stage('Create Namespace') {
            steps {
                sh '''
                    export KUBECONFIG=${WORKSPACE}/.kube/config
                    kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                    kubectl get namespace ${K8S_NAMESPACE}
                '''
            }
        }

        stage('Deploy MySQL to Kubernetes') {
            steps {
                sh """
                    export KUBECONFIG=${WORKSPACE}/.kube/config
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
                    export KUBECONFIG=${WORKSPACE}/.kube/config

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
                    export KUBECONFIG=${WORKSPACE}/.kube/config
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
                    export KUBECONFIG=${WORKSPACE}/.kube/config
                    MINIKUBE_IP=\$(minikube ip)
                    echo "http://\${MINIKUBE_IP}:30080"
                """
            }
        }
    }

    post {
        success {
            echo "Image: ${DOCKERHUB_REPO}:${IMAGE_TAG}"
            echo "Namespace: ${K8S_NAMESPACE}"
        }

        failure {
            echo "Pipeline failed"
        }

        always {
            sh '''
                docker system prune -f || true
            '''
        }
    }
}
