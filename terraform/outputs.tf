output "app_url" {
  description = "URL de l'application SentimentAI"
  value       = "http://localhost:${var.app_port}"
}

output "sonarqube_url" {
  description = "URL de SonarQube"
  value       = "http://localhost:${var.sonarqube_port}"
}

output "app_container_id" {
  description = "ID du conteneur SentimentAI"
  value       = docker_container.sentiment_ai.id
}

output "sonarqube_container_id" {
  description = "ID du conteneur SonarQube"
  value       = docker_container.sonarqube.id
}

output "network_id" {
  description = "ID du réseau Docker"
  value       = docker_network.cicd.id
}

output "image_id" {
  description = "ID de l'image SentimentAI buildée"
  value       = docker_image.sentiment_ai.image_id
}
