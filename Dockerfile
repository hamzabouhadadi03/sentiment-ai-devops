FROM python:3.11-slim

WORKDIR /app

# Copier uniquement le fichier de dépendances en premier
# Cette couche est mise en cache tant que requirements.txt ne change pas
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copier le code source (invalidé à chaque modification du code)
COPY src/ ./src/
COPY tests/ ./tests/

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
