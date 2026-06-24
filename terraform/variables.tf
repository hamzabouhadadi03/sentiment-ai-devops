variable "docker_host" {
  description = "Socket Docker à utiliser"
  type        = string
  default     = "npipe:////./pipe/docker_engine"
}

variable "network_name" {
  description = "Nom du réseau Docker créé par Terraform"
  type        = string
  default     = "tf-cicd-network"
}

variable "image_name" {
  description = "Nom de l'image Docker de l'application"
  type        = string
  default     = "sentiment-ai"
}

variable "image_tag" {
  description = "Tag de l'image Docker"
  type        = string
  default     = "terraform"
}

variable "container_name" {
  description = "Nom du conteneur applicatif"
  type        = string
  default     = "tf-sentiment-ai"
}

variable "app_port" {
  description = "Port exposé de l'application"
  type        = number
  default     = 8081
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "staging"
}

variable "sonarqube_port" {
  description = "Port exposé de SonarQube"
  type        = number
  default     = 9001
}

variable "sonar_db_user" {
  description = "Utilisateur PostgreSQL pour SonarQube"
  type        = string
  default     = "sonar"
}

variable "sonar_db_password" {
  description = "Mot de passe PostgreSQL pour SonarQube"
  type        = string
  sensitive   = true
  default     = "sonar"
}

variable "sonar_db_name" {
  description = "Nom de la base de données SonarQube"
  type        = string
  default     = "sonar"
}
