from io import BytesIO

from fastapi.testclient import TestClient
from PIL import Image

from ai_service import app as service
from ai_service.symptom_analyzer import _load_classes


client = TestClient(service.app)


def test_supported_disease_labels_match_checkpoint_contract():
    assert _load_classes(service.SERVICE_DIR) == [
        "Acne",
        "Actinic Keratosis",
        "Benign Tumors",
        "Bullous",
        "Candidiasis",
        "Drug Eruption",
        "Eczema",
        "Infestations/Bites",
        "Lichen",
        "Lupus",
        "Moles",
        "Psoriasis",
        "Rosacea",
        "Seborrheic Keratoses",
        "Skin Cancer",
        "Sun/Sunlight Damage",
        "Tinea",
        "Unknown/Normal",
        "Vascular Tumors",
        "Vasculitis",
        "Vitiligo",
        "Warts",
    ]


def test_health_does_not_load_optional_model():
    service.get_classifier.cache_clear()
    assert client.get("/health").json() == {"status": "ok", "model_loaded": False}


def test_predict_rejects_non_image_upload():
    response = client.post("/predict", files={"file": ("report.pdf", b"data", "application/pdf")})
    assert response.status_code == 400


def test_predict_rejects_corrupted_image():
    response = client.post("/predict", files={"file": ("photo.jpg", b"not-an-image", "image/jpeg")})
    assert response.status_code == 400


def test_predict_returns_top_three_when_classifier_is_available(monkeypatch):
    expected = [{"disease": "eczema", "confidence": 0.7}]

    class Classifier:
        def predict_topk(self, image, k):
            assert image.size == (4, 3)
            assert k == 3
            return expected

    monkeypatch.setattr(service, "get_classifier", lambda: Classifier())
    image = Image.new("RGB", (4, 3), "white")
    buffer = BytesIO()
    image.save(buffer, format="JPEG")
    response = client.post("/predict", files={"file": ("photo.jpg", buffer.getvalue(), "image/jpeg")})

    assert response.status_code == 200
    assert response.json() == {"source": "image-model", "results": expected}


def test_chat_requires_non_empty_symptoms():
    response = client.post("/chat", json={"symptoms": "   "})
    assert response.status_code == 400


def test_chat_returns_gemini_candidates(monkeypatch):
    expected = [{"disease": "eczema", "confidence": 0.7, "reason": "ngứa"}]
    monkeypatch.setattr("ai_service.symptom_analyzer.analyze_symptoms", lambda symptoms, service_dir: expected)
    response = client.post("/chat", json={"symptoms": "  ngứa  "})
    assert response.status_code == 200
    assert response.json() == {"source": "gemini", "results": expected}


def test_chat_reports_missing_key_as_service_unavailable(monkeypatch):
    monkeypatch.setattr("ai_service.symptom_analyzer.analyze_symptoms", lambda *args: (_ for _ in ()).throw(RuntimeError("GEMINI_API_KEY is missing")))
    response = client.post("/chat", json={"symptoms": "itchy rash"})
    assert response.status_code == 503
