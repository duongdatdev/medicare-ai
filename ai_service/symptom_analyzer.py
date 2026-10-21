"""Gemini-backed symptom analysis constrained to the supported disease labels."""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any


def _load_classes(service_dir: Path) -> list[str]:
    class_file = service_dir / "classes.txt"
    if not class_file.exists():
        return []
    return [line.strip() for line in class_file.read_text(encoding="utf-8").splitlines() if line.strip()]


def _extract_results(data: Any) -> Any:
    if isinstance(data, dict):
        for key in ("results", "diseases", "top3", "data"):
            if isinstance(data.get(key), list):
                return data[key]
    return data


def analyze_symptoms(symptoms: str, service_dir: Path) -> Any:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY chưa được cấu hình.")

    from google import genai
    from google.genai import types

    classes = _load_classes(service_dir)
    class_list = ", ".join(classes) if classes else "danh sách bệnh da liễu phổ biến"
    prompt = (
        f'Bệnh nhân mô tả triệu chứng: "{symptoms}". '
        f"Chỉ chọn trong danh sách {len(classes)} bệnh: [{class_list}]. "
        'Trả về JSON là một mảng tối đa ba object có "disease", '
        '"confidence" (số từ 0 đến 1), và "reason" (tiếng Việt ngắn gọn).'
    )
    client = genai.Client(api_key=api_key)
    response = client.models.generate_content(
        model=os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
        contents=prompt,
        config=types.GenerateContentConfig(response_mime_type="application/json"),
    )

    try:
        return _extract_results(json.loads(response.text))
    except (json.JSONDecodeError, TypeError):
        return {"raw": response.text}
