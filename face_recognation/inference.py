# face_recognation/inference.py
import torch
from PIL import Image
from model import FaceClassifier

ckpt = torch.load("dataset/model.pt", map_location="cpu")
classes = ckpt["classes"]

model = FaceClassifier(num_classes=len(classes))
model.load_state_dict(ckpt["model_state_dict"])
model.eval()

img = Image.open("person2.jpg").convert("RGB")
results = model.predict_from_pil(img, topk=3, classes=classes)
print(results)