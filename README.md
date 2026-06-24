# SentimentAI — Pipeline DevOps Complet

API REST d'analyse de sentiments construite avec FastAPI, conteneurisée avec Docker et intégrée dans un pipeline CI/CD complet avec Jenkins, SonarQube, Trivy, Terraform et Grafana.

---

## Contexte

Ce projet a été réalisé dans le cadre des TPs DevOps de la formation. L'objectif était de mettre en place une infrastructure DevOps complète pour **SentimentAI**, une API qui analyse le sentiment d'un texte et retourne un label (POSITIVE, NEGATIVE, NEUTRAL) avec un score de confiance.

Le projet couvre 5 TPs progressifs :

| TP | Sujet | Ce qui a été fait |
|----|-------|-------------------|
| TP1 | Git & Docker | Structure du projet, code FastAPI, tests, Dockerfile, Docker Compose, Makefile, tag v0.1.0 |
| TP2 | Jenkins Pipeline | Jenkinsfile 4 stages : Checkout → Lint → Build & Test → Push |
| TP3 | Qualité & Sécurité | Pipeline 8 stages + SonarQube (Quality Gate) + Trivy (scan CVE) |
| TP4 | Terraform & IaC | Infrastructure provisionnée en code avec le Docker provider |
| TP5 | Monitoring | Métriques Prometheus exposées sur `/metrics`, dashboard Grafana |

---

## Structure du projet

```
sentiment-ai/
├── src/
│   ├── main.py          # Application FastAPI + exposition /metrics
│   ├── model.py         # Modèle d'analyse de sentiment
│   └── schemas.py       # Schémas Pydantic (validation des données)
├── tests/
│   └── test_api.py      # 3 tests pytest (coverage 91%)
├── terraform/
│   ├── main.tf          # Ressources Docker (réseau, volumes, conteneurs)
│   ├── variables.tf     # Variables paramétrables
│   ├── outputs.tf       # URLs et IDs en sortie
│   └── terraform.tfvars # Valeurs concrètes
├── monitoring/
│   ├── prometheus.yml   # Configuration scrape Prometheus
│   └── grafana/
│       ├── provisioning/ # Datasource et dashboards auto-provisionnés
│       └── dashboards/   # Dashboard SentimentAI (6 panels)
├── Dockerfile           # Image python:3.11-slim
├── docker-compose.yml   # Stack complète (app + SonarQube + Prometheus + Grafana)
├── Jenkinsfile          # Pipeline CI/CD 8 stages
├── sonar-project.properties  # Configuration analyse SonarQube
├── Makefile             # Commandes build, test, run, clean
└── requirements.txt     # Dépendances Python épinglées
```

---

## Lancer le projet

### Prérequis
- Docker Desktop
- Terraform >= 1.0

### Démarrage rapide avec Docker Compose

```bash
# Lancer l'application
docker compose up -d sentiment-ai

# Tester l'API
curl http://localhost:8082/health
curl -X POST http://localhost:8082/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Ce produit est excellent !"}'
```

### Lancer toute la stack (app + monitoring)

```bash
docker compose up -d
```

| Service | URL |
|---------|-----|
| SentimentAI | http://localhost:8082 |
| Métriques | http://localhost:8082/metrics |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 (admin/admin) |
| SonarQube | http://localhost:9000 |

---

## Infrastructure as Code (Terraform)

L'infrastructure est déclarée en code dans le dossier `terraform/`. Le provider utilisé est `kreuzwerker/docker` — ce qui permet de travailler en local sans compte cloud, tout en appliquant exactement les mêmes principes que sur AWS, GCP ou Azure.

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

Les ressources créées par Terraform :
- Réseau Docker `tf-cicd-network`
- Volumes persistants pour SonarQube et sa base PostgreSQL
- Conteneurs : `tf-sentiment-ai`, `tf-sonarqube`, `tf-sonar-db`

---

## Pipeline CI/CD Jenkins — 8 stages

```
Checkout → Lint → Build & Test → SonarQube Analysis → Quality Gate → Trivy Scan → Push → Notify
```

| Stage | Rôle |
|-------|------|
| Checkout | Clone le repo, affiche le commit et la branche |
| Lint | Analyse statique Python avec flake8 (fail fast) |
| Build & Test | Build de l'image Docker + pytest + rapport coverage.xml |
| SonarQube Analysis | Scan du code source (bugs, code smells, duplication) |
| Quality Gate | Bloque le pipeline si coverage < 70% ou bugs détectés |
| Trivy Scan | Scan des CVE HIGH/CRITICAL dans l'image (`--ignore-unfixed`) |
| Push | Push vers GHCR (branche `main` uniquement) |
| Notify | Affiche les URLs SonarQube et Trivy |

---

## Tests et qualité

```bash
# Lancer les tests
make test

# Résultats
# tests/test_api.py::test_health               PASSED
# tests/test_api.py::test_predict_positive     PASSED
# tests/test_api.py::test_predict_empty_fails  PASSED
# Coverage: 91% (seuil minimum : 70%)
```

Le Quality Gate SonarQube est configuré pour bloquer le pipeline si la couverture passe sous 70% ou si des bugs sont détectés.

---

## Monitoring

L'API expose ses métriques HTTP sur `GET /metrics` via `prometheus-fastapi-instrumentator`. Prometheus scrape ces métriques toutes les 15 secondes. Le dashboard Grafana affiche :

- Requêtes HTTP par seconde
- Latence p50 / p95 / p99
- Total requêtes
- Taux d'erreurs 4xx + 5xx
- Latence moyenne sur `/predict`
- Requêtes en cours

---

## API Reference

### `GET /health`
```json
{ "status": "ok" }
```

### `POST /predict`
**Body :**
```json
{ "text": "Ce produit est vraiment bien !" }
```
**Réponse :**
```json
{
  "label": "POSITIVE",
  "score": 0.7,
  "text": "Ce produit est vraiment bien !"
}
```

Les labels possibles sont `POSITIVE`, `NEGATIVE` et `NEUTRAL`. Le score est compris entre 0 et 1.

---

## Tag de version

```bash
git tag -l
# v0.1.0
```

Ce tag marque la première version livrable de SentimentAI, correspondant à la fin du TP1.
