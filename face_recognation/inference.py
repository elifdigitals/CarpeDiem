import torch
from torchvision import transforms
from PIL import Image
import io
from typing import Tuple, List

from face_recognation.model import FaceClassifier

DEFAULT_MODEL_PATH = "dataset/model.pt"

_transform = transforms.Compose([
    transforms.Resize((224,224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225]),
])

class FaceRecognizer:
    def __init__(self, model_path: str = DEFAULT_MODEL_PATH, device: str = None):
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        ckpt = torch.load(model_path, map_location=self.device)
        classes = ckpt.get("classes")
        if classes is None:
            raise RuntimeError("Model checkpoint does not contain 'classes' list.")
        self.classes = classes
        num_classes = len(classes)
        self.model = FaceClassifier(num_classes=num_classes, pretrained=False)
        self.model.load_state_dict(ckpt["model_state_dict"])
        self.model.to(self.device)
        self.model.eval()

    def predict_from_pil(self, img: Image.Image, topk: int = 1) -> List[Tuple[str, float]]:
        img_t = _transform(img).unsqueeze(0).to(self.device)  # (1,3,224,224)
        with torch.no_grad():
            logits = self.model(img_t)
            probs = torch.softmax(logits, dim=1)[0]
            topk_vals, topk_idx = torch.topk(probs, k=topk)
            results = []
            for val, idx in zip(topk_vals.cpu().tolist(), topk_idx.cpu().tolist()):
                results.append((self.classes[idx], float(val)))
            return results

    def predict_from_bytes(self, data: bytes, topk: int = 1):
        img = Image.open(io.BytesIO(data)).convert("RGB")
        return self.predict_from_pil(img, topk=topk)
