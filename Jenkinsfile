// Jenkinsfile - Pipeline CI/CD SentimentAI
// Phase 9 : 8 stages - Checkout, Lint, Build & Test, SonarQube, Quality Gate,
//                      Trivy Scan, Push, Notify

pipeline {
    agent any

    environment {
        IMAGE_NAME   = 'sentiment-ai'
        REGISTRY     = 'ghcr.io/hamzabouhadadi03'
        IMAGE_TAG    = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        SONAR_URL    = 'http://sonarqube:9000'
        TRIVY_REPORT = 'trivy-report.json'
    }

    stages {

        // ── 1. Récupération du code ──────────────────────────────────────────
        stage('Checkout') {
            steps {
                checkout scm
                echo "Branche : ${env.BRANCH_NAME}"
                echo "Commit  : ${env.GIT_COMMIT}"
                sh 'git log --oneline -5'
            }
        }

        // ── 2. Analyse statique du code ──────────────────────────────────────
        stage('Lint') {
            steps {
                sh '''
                    docker run --rm \
                        --volumes-from jenkins \
                        -w $WORKSPACE \
                        python:3.11-slim \
                        sh -c "pip install flake8 -q && flake8 src/ --max-line-length=100"
                '''
            }
        }

        // ── 3. Build de l'image + tests unitaires + couverture ───────────────
        stage('Build & Test') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
                sh """
                    docker run --rm \
                        --volumes-from jenkins \
                        -w \$WORKSPACE \
                        ${IMAGE_NAME}:${IMAGE_TAG} \
                        pytest tests/ -v \
                            --cov=src \
                            --cov-report=term-missing \
                            --cov-report=xml:coverage.xml \
                            --cov-fail-under=70
                """
            }
            post {
                failure {
                    echo 'Tests échoués ou coverage insuffisant (< 70%)'
                }
            }
        }

        // ── 4. Analyse SonarQube ─────────────────────────────────────────────
        stage('SonarQube Analysis') {
            steps {
                sh """
                    docker run --rm \
                        --network cicd-network \
                        --volumes-from jenkins \
                        -w \$WORKSPACE \
                        -e SONAR_HOST_URL=${SONAR_URL} \
                        -e SONAR_TOKEN=sqa_6320665c5283b5a4a1a3346fc31ccd7f958fcc8b \
                        sonarsource/sonar-scanner-cli:latest \
                        sonar-scanner \
                            -Dsonar.projectKey=${IMAGE_NAME} \
                            -Dsonar.sources=src \
                            -Dsonar.tests=tests \
                            -Dsonar.python.coverage.reportPaths=coverage.xml \
                            -Dsonar.projectVersion=${IMAGE_TAG}
                """
            }
        }

        // ── 5. Vérification du Quality Gate ─────────────────────────────────
        stage('Quality Gate') {
            steps {
                sh """
                    STATUS=""
                    for i in \$(seq 1 10); do
                        STATUS=\$(curl -s -u admin:Admin2024!!! \
                            "${SONAR_URL}/api/qualitygates/project_status?projectKey=${IMAGE_NAME}" \
                            | python3 -c "import sys,json; print(json.load(sys.stdin)['projectStatus']['status'])")
                        echo "Quality Gate status: \$STATUS"
                        if [ "\$STATUS" = "OK" ] || [ "\$STATUS" = "ERROR" ]; then
                            break
                        fi
                        sleep 15
                    done
                    if [ "\$STATUS" != "OK" ]; then
                        echo "Quality Gate échoué (\$STATUS) — pipeline bloqué."
                        exit 1
                    fi
                    echo "Quality Gate PASSED"
                """
            }
            post {
                failure {
                    echo 'Quality Gate échoué — le pipeline est bloqué.'
                }
            }
        }

        // ── 6. Scan de vulnérabilités Trivy ──────────────────────────────────
        stage('Trivy Scan') {
            steps {
                sh """
                    docker run --rm \
                        --volumes-from jenkins \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -w \$WORKSPACE \
                        aquasec/trivy:latest image \
                            --exit-code 1 \
                            --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --format json \
                            --output ${TRIVY_REPORT} \
                            ${IMAGE_NAME}:${IMAGE_TAG} || true
                """
                // Archiver le rapport même en cas d'échec
                archiveArtifacts artifacts: "${TRIVY_REPORT}", allowEmptyArchive: true
                // Échouer si des vulnérabilités CRITICAL sont trouvées
                sh """
                    CRITICAL=\$(docker run --rm \
                        -v \$WORKSPACE/${TRIVY_REPORT}:/report.json \
                        aquasec/trivy:latest \
                        --quiet convert --format table /report.json 2>/dev/null | grep -c CRITICAL || true)
                    echo "Vulnérabilités CRITICAL : \$CRITICAL"
                    if [ "\$CRITICAL" -gt 0 ]; then
                        echo "Des vulnérabilités CRITICAL ont été détectées — pipeline bloqué."
                        exit 1
                    fi
                """
            }
            post {
                always {
                    echo "Rapport Trivy archivé : ${TRIVY_REPORT}"
                }
            }
        }

        // ── 7. Push vers le registry ─────────────────────────────────────────
        stage('Push') {
            when { branch 'main' }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-token',
                    usernameVariable: 'REGISTRY_USER',
                    passwordVariable: 'REGISTRY_PASS'
                )]) {
                    sh """
                        echo \$REGISTRY_PASS | docker login ghcr.io \
                            -u \$REGISTRY_USER --password-stdin
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:latest
                        docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${REGISTRY}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        // ── 8. Notification du résultat ──────────────────────────────────────
        stage('Notify') {
            steps {
                echo "Pipeline terminé — Image : ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                echo "SonarQube  : ${SONAR_URL}/dashboard?id=${IMAGE_NAME}"
                echo "Trivy      : voir artefact ${TRIVY_REPORT}"
            }
        }

    }

    post {
        always {
            sh 'docker compose down -v 2>/dev/null || true'
            deleteDir()
        }
        success {
            echo "Pipeline réussi ! Image poussée : ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline échoué. Consultez les logs ci-dessus.'
        }
    }
}
