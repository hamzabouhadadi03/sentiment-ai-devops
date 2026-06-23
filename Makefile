IMAGE_NAME = sentiment-ai
PORT       = 8080

# .PHONY indique que ces cibles ne correspondent pas à des fichiers réels
.PHONY: build run test stop clean tag

## build : construit l'image Docker locale taguée "latest"
build:
	docker build -t $(IMAGE_NAME):latest .

## run : démarre la stack Docker Compose en arrière-plan
run:
	docker compose up -d

## test : lance pytest DANS le conteneur Docker
##        garantit que les tests tournent dans le même env que la prod
test:
	docker run --rm \
		-v "$(CURDIR):/app" \
		-w /app \
		$(IMAGE_NAME):latest \
		pytest tests/ -v --cov=src --cov-report=term-missing

## stop : arrête et supprime les conteneurs Docker Compose
stop:
	docker compose down

## clean : arrête la stack ET supprime l'image locale
clean:
	docker compose down
	docker rmi $(IMAGE_NAME):latest || true

## tag : crée un tag Git annoté v0.1.0 et le pousse vers GitHub
tag:
	git tag -a v0.1.0 -m "Initial SentimentAI release"
	git push origin v0.1.0
