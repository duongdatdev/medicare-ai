# AI service

FastAPI service for the DACN NestJS backend. It exposes `/health`, `/predict` (multipart field `file`) and `/chat` (`{"symptoms":"..."}`).

Run from this directory with `python -m venv .venv`, activate the environment, install `requirements.txt`, copy `.env.example` to `.env`, provide a Gemini key and model checkpoint, then run `uvicorn ai_service.app:app --host 0.0.0.0 --port 8000` from the repository root.

The Swin V2 weights are supplied separately with `MODEL_PTH`. The model is loaded on the first image request, so `/health` remains available when optional model dependencies, weights or credentials are absent.
