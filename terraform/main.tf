terraform {
  required_version = ">= 1.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

# ── Réseau ───────────────────────────────────────────────────────────────────

resource "docker_network" "cicd" {
  name   = var.network_name
  driver = "bridge"
}

# ── Images ───────────────────────────────────────────────────────────────────

resource "docker_image" "sentiment_ai" {
  name         = "${var.image_name}:${var.image_tag}"
  keep_locally = true
}

resource "docker_image" "postgres" {
  name         = "postgres:15-alpine"
  keep_locally = true
}

resource "docker_image" "sonarqube" {
  name         = "sonarqube:community"
  keep_locally = true
}

# ── Volumes SonarQube ────────────────────────────────────────────────────────

resource "docker_volume" "sonarqube_data" {
  name = "tf_sonarqube_data"
}

resource "docker_volume" "sonarqube_logs" {
  name = "tf_sonarqube_logs"
}

resource "docker_volume" "sonarqube_extensions" {
  name = "tf_sonarqube_extensions"
}

resource "docker_volume" "sonar_db_data" {
  name = "tf_sonar_db_data"
}

# ── PostgreSQL (base SonarQube) ───────────────────────────────────────────────

resource "docker_container" "sonar_db" {
  name  = "tf-sonar-db"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = docker_network.cicd.name
  }

  env = [
    "POSTGRES_USER=${var.sonar_db_user}",
    "POSTGRES_PASSWORD=${var.sonar_db_password}",
    "POSTGRES_DB=${var.sonar_db_name}",
  ]

  volumes {
    volume_name    = docker_volume.sonar_db_data.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U ${var.sonar_db_user} -d ${var.sonar_db_name}"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }

  restart = "unless-stopped"
}

# ── SonarQube ────────────────────────────────────────────────────────────────

resource "docker_container" "sonarqube" {
  name  = "tf-sonarqube"
  image = docker_image.sonarqube.image_id

  networks_advanced {
    name = docker_network.cicd.name
  }

  ports {
    internal = 9000
    external = var.sonarqube_port
  }

  env = [
    "SONAR_JDBC_URL=jdbc:postgresql://${docker_container.sonar_db.name}:5432/${var.sonar_db_name}",
    "SONAR_JDBC_USERNAME=${var.sonar_db_user}",
    "SONAR_JDBC_PASSWORD=${var.sonar_db_password}",
  ]

  volumes {
    volume_name    = docker_volume.sonarqube_data.name
    container_path = "/opt/sonarqube/data"
  }

  volumes {
    volume_name    = docker_volume.sonarqube_logs.name
    container_path = "/opt/sonarqube/logs"
  }

  volumes {
    volume_name    = docker_volume.sonarqube_extensions.name
    container_path = "/opt/sonarqube/extensions"
  }

  healthcheck {
    test         = ["CMD-SHELL", "curl -sf http://localhost:9000/api/system/status | grep -q UP || exit 1"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 10
    start_period = "120s"
  }

  restart = "unless-stopped"

  depends_on = [docker_container.sonar_db]
}

# ── Application SentimentAI ───────────────────────────────────────────────────

resource "docker_container" "sentiment_ai" {
  name  = var.container_name
  image = docker_image.sentiment_ai.image_id

  networks_advanced {
    name = docker_network.cicd.name
  }

  ports {
    internal = 8000
    external = var.app_port
  }

  env = [
    "ENV=${var.environment}",
  ]

  healthcheck {
    test         = ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "10s"
  }

  restart = "unless-stopped"
}
