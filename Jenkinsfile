pipeline {
    agent any
     triggers {
            githubPush()
        }
    
    tools {
        maven 'maven'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Récupération du code depuis GitHub...'
                git branch: 'main', url: 'https://github.com/benghorbelmenyar/DevopsTest.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Compilation du projet...'
                sh 'mvn clean compile'
            }
        }

        stage('Package') {
            steps {
                echo 'Création du JAR...'
                sh 'mvn package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Construction de l\'image Docker...'
                sh 'docker build -t student-management:latest .'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Déploiement du conteneur...'
                sh '''
                    docker stop student-app || true
                    docker rm student-app || true
                    docker run -d \
                      --name student-app \
                      -p 8090:8090 \
                      student-management:latest
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline réussi avec succès'
        }
        failure {
            echo 'Pipeline échoué - Vérifiez les logs'
        }
    }
}