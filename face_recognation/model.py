import os
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from PIL import Image
import numpy as np

from torchvision import models

resnet = models.resnet18(pretrained=True)
resnet = nn.Sequential(*list(resnet.children())[:-1])


class FaceDataset(Dataset):
    def __init__(self, image_dir, transform=None):
        self.image_dir = image_dir
        self.transform = transform
        self.labels = []
        self.images = []
        self.label_map = {}

        for i, person_folder in enumerate(os.listdir(image_dir)):
            person_path = os.path.join(image_dir, person_folder)
            if os.path.isdir(person_path):
                self.label_map[i] = person_folder
                for img_name in os.listdir(person_path):
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


transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_PATH = os.path.join(BASE_DIR, '..', 'dataset')
dataset = FaceDataset(DATASET_PATH, transform=transform)
train_loader = DataLoader(dataset, batch_size=32, shuffle=True)


class FaceClassifier(nn.Module):
    def __init__(self, num_classes):
        super(FaceClassifier, self).__init__()
        self.resnet = resnet
        self.fc = nn.Linear(512, num_classes)

        # if model_path is not None:
        #     ckpt = torch.load(model_path, map_location=torch.device('cpu'))
        #     self.load_state_dict(ckpt['model_state_dict'])

    def forward(self, x):
        x = self.resnet(x)
        x = x.view(x.size(0), -1)
        x = self.fc(x)
        return x


model = FaceClassifier(num_classes=len(dataset.label_map))
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
criterion = nn.CrossEntropyLoss()

for epoch in range(10):
    model.train()
    running_loss = 0.0
    for images, labels in train_loader:
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        running_loss += loss.item()

    print(f"Epoch [{epoch + 1}/10], Loss: {running_loss / len(train_loader):.4f}")
    print(len(train_loader))

torch.save(model.state_dict(), "dataset/model.pt")
