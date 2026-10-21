"""Swin V2 image classifier compatible with the DACN checkpoint format."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image


def _device(torch):
    if torch.cuda.is_available():
        return torch.device("cuda")
    if getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


class SkinDiseaseClassifier:
    def __init__(self, model, class_names, device, transform):
        self.model = model
        self.class_names = class_names
        self.device = device
        self.transform = transform

    @classmethod
    def from_environment(cls, service_dir: Path):
        import timm
        import torch
        import torch.nn as nn
        from torchvision import transforms

        weights_path = Path(os.getenv("MODEL_PTH", str(service_dir / "skin_disease_swinv2_best.pth")))
        if not weights_path.is_absolute():
            weights_path = service_dir / weights_path
        if not weights_path.is_file():
            raise FileNotFoundError(
                f"Model weights not found: {weights_path}. Configure MODEL_PTH to the supplied checkpoint."
            )

        device = _device(torch)
        checkpoint = torch.load(weights_path, map_location=device, weights_only=False)
        state_dict = checkpoint.get("model_state_dict", checkpoint.get("state_dict", checkpoint))
        model_name = checkpoint.get("model_name", "swinv2_base_window16_256")
        class_names = checkpoint.get("class_names") or cls._load_class_names(service_dir)
        num_classes = checkpoint.get("num_classes", len(class_names) or 22)
        class_names = class_names or [f"Class {index}" for index in range(num_classes)]

        backbone = timm.create_model(model_name, pretrained=False, num_classes=0)
        input_features = backbone.num_features
        hidden_dim = state_dict.get("head.6.weight", torch.empty(22, 512)).shape[1]
        model = _SwinClassifier(backbone, input_features, hidden_dim, num_classes, nn)
        model.load_state_dict(state_dict, strict=False)
        model.to(device).eval()

        image_size = int(os.getenv("IMAGE_SIZE", "256"))
        transform = transforms.Compose(
            [
                transforms.Resize((image_size, image_size)),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
            ]
        )
        return cls(model, class_names, device, transform)

    @staticmethod
    def _load_class_names(service_dir: Path) -> list[str]:
        classes_file = service_dir / "classes.txt"
        if not classes_file.exists():
            return []
        return [line.strip() for line in classes_file.read_text(encoding="utf-8").splitlines() if line.strip()]

    def predict_topk(self, image: Image.Image, k: int = 3):
        import torch
        import torch.nn.functional as functional

        tensor = self.transform(image.convert("RGB")).unsqueeze(0).to(self.device)
        with torch.inference_mode():
            probabilities = functional.softmax(self.model(tensor), dim=1)[0]
            scores, indices = torch.topk(probabilities, min(k, len(self.class_names)))
        return [
            {
                "disease": self.class_names[index.item()] if index.item() < len(self.class_names) else f"Class {index.item()}",
                "confidence": round(score.item(), 4),
            }
            for score, index in zip(scores, indices)
        ]


class _SwinClassifier:
    def __new__(cls, backbone, input_features, hidden_dim, num_classes, nn):
        class Model(nn.Module):
            def __init__(self):
                super().__init__()
                self.backbone = backbone
                self.head = nn.Sequential(
                    nn.BatchNorm1d(input_features),
                    nn.Dropout(0.25),
                    nn.Linear(input_features, hidden_dim),
                    nn.ReLU(inplace=True),
                    nn.BatchNorm1d(hidden_dim),
                    nn.Dropout(0.5),
                    nn.Linear(hidden_dim, num_classes),
                )

            def forward(self, inputs):
                return self.head(self.backbone(inputs))

        return Model()
