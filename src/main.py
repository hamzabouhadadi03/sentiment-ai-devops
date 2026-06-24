from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from src.schemas import PredictionRequest, PredictionResponse
from src.model import SentimentModel

app = FastAPI(title="SentimentAI", version="0.1.0")

model = SentimentModel()

Instrumentator().instrument(app).expose(app)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest):
    return model.predict(request.text)
