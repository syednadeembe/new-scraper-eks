from datetime import datetime, timezone
import os

from fastapi import FastAPI
from pymongo import MongoClient
from scraper import scrape_news

app = FastAPI(title="News Scraper API")

MONGO_URL = os.getenv("MONGO_URL", "mongodb://mongo:27017")
client = MongoClient(MONGO_URL, serverSelectionTimeoutMS=3000)
collection = client["news_app"]["news"]


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/search")
def search_news(topic: str):
    existing = collection.find_one({"topic": topic})
    if existing:
        return {"source": "cache", "results": existing["results"]}

    results = scrape_news(topic)
    collection.insert_one(
        {"topic": topic, "results": results, "created_at": datetime.now(timezone.utc)}
    )
    return {"source": "scraped", "results": results}


@app.get("/history")
def get_history():
    history = collection.find({}, {"_id": 0, "topic": 1, "created_at": 1})
    return list(history)
