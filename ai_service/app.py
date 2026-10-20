"""HTTP API for image-based and symptom-based skin disease suggestions."""

from __future__ import annotations

import io
import os
from functools import lru_cache
from pathlib import Path
from typing import Annotated

from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError
from pydantic import BaseModel, Field

SERVICE_DIR = Path(__file__).resolve().parent
load_dotenv(SERVICE_DIR / ".env")

app = FastAPI(title="DACN AI Service", version="1.0.0")


@lru_cache(maxsize=1)
def get_classifier():
    from .classifier import SkinDiseaseClassifier

    return SkinDiseaseClassifier.from_environment(SERVICE_DIR)


class ChatRequest(BaseModel):
    symptoms: Annotated[str, Field(min_length=1, max_length=4000)]


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": get_classifier.cache_info().currsize > 0}


@app.post("/predict")
async def predict(file: Annotated[UploadFile, File()]):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File phải là ảnh.")

    try:
        raw = await file.read()
        with Image.open(io.BytesIO(raw)) as image:
            image.load()
            results = get_classifier().predict_topk(image, k=3)
    except (UnidentifiedImageError, OSError, ValueError):
        raise HTTPException(status_code=400, detail="Không đọc được ảnh.") from None
    except FileNotFoundError as error:
        raise HTTPException(status_code=503, detail=str(error)) from None
    except Exception as error:
        raise HTTPException(status_code=500, detail=f"Lỗi inference: {error}") from None

    return {"source": "image-model", "results": results}


@app.post("/chat")
def chat(request: ChatRequest):
    symptoms = request.symptoms.strip()
    if not symptoms:
        raise HTTPException(status_code=400, detail="Thiếu mô tả triệu chứng.")

    try:
        from .symptom_analyzer import analyze_symptoms

        results = analyze_symptoms(symptoms, SERVICE_DIR)
    except RuntimeError as error:
        raise HTTPException(status_code=503, detail=str(error)) from None
    except Exception as error:
        raise HTTPException(status_code=500, detail=f"Lỗi gọi Gemini: {error}") from None

    return {"source": "gemini", "results": results}
