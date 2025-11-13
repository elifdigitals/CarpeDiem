import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image

class FaceClassifier(nn.Module):
    def __init__(self, num_classes):
        super().__init__()
        backbone = models.resnet18(pretrained=True)
        self.feature_extractor = nn.Sequential(*list(backbone.children())[:-1])
        self.fc = nn.Linear(512, num_classes)

    def forward(self, x):
        x = self.feature_extractor(x)
        x = x.view(x.size(0), -1)
        x = self.fc(x)
        return x

    @torch.no_grad()
    def predict_from_pil(self, img, topk=1, classes=None):
        """Возвращает top-k (класс, вероятность)"""
        transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                 std=[0.229, 0.224, 0.225]),
        ])
        tensor = transform(img).unsqueeze(0)
        logits = self.forward(tensor)
        probs = torch.softmax(logits, dim=1)
        conf, idx = probs.topk(topk, dim=1)
        results = []
        for c, i in zip(conf[0], idx[0]):
            name = classes[i] if classes is not None else int(i)
            results.append((name, float(c)))
        return results
