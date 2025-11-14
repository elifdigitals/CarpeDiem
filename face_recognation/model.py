import os
import torch
import torch.nn as nn
from torch.utils.data import Dataset
from torchvision import models, transforms
from PIL import Image


class FaceDataset(Dataset):
    def __init__(self, image_dir, transform=None):
        self.image_dir = image_dir
        self.transform = transform

        self.images = []
        self.labels = []
        self.label_map = {}

        for i, person_folder in enumerate(os.listdir(image_dir)):
            person_path = os.path.join(image_dir, person_folder)

            if not os.path.isdir(person_path):
                continue

            self.label_map[i] = person_folder

            for img_name in os.listdir(person_path):
                if img_name.lower().endswith((".jpg", ".jpeg", ".png")):
                    img_path = os.path.join(person_path, img_name)
                    self.images.append(img_path)
                    self.labels.append(i)

    def __len__(self):
        return len(self.images)

    def __getitem__(self, idx):
        img_path = self.images[idx]
        label = self.labels[idx]
        img = Image.open(img_path).convert("RGB")

        if self.transform:
            img = self.transform(img)

        return img, label


class FaceClassifier(nn.Module):
    def __init__(self, num_classes):
        super().__init__()

        resnet = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
        self.feature_extractor = nn.Sequential(*list(resnet.children())[:-1])
        self.fc = nn.Linear(512, num_classes)

    def forward(self, x):
        x = self.feature_extractor(x)
        x = x.view(x.size(0), -1)
        x = self.fc(x)
        return x
