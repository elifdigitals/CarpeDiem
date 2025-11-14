import os
import argparse
from pathlib import Path
import torch
from torch.utils.data import DataLoader
from torchvision import transforms, datasets
import torch.nn as nn
import torch.optim as optim
from tqdm import tqdm
from model import FaceClassifier

def train(data_dir, save_path, epochs=10, batch_size=32, lr=1e-4):
    device = "cuda" if torch.cuda.is_available() else "cpu"

    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.RandomHorizontalFlip(),
        transforms.ColorJitter(0.1,0.1,0.1,0.1),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225]),
    ])

    dataset = datasets.ImageFolder(data_dir, transform=transform)
    loader = DataLoader(dataset, batch_size=batch_size, shuffle=True, num_workers=4)
    model = FaceClassifier(num_classes=len(dataset.classes)).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=lr)

    for epoch in range(1, epochs + 1):
        model.train()
        total_loss, correct, total = 0.0, 0, 0
        pbar = tqdm(loader, desc=f"Epoch {epoch}/{epochs}")
        for imgs, labels in pbar:
            imgs, labels = imgs.to(device), labels.to(device)
            optimizer.zero_grad()
            logits = model(imgs)
            loss = criterion(logits, labels)
            loss.backward()
            optimizer.step()

            total_loss += loss.item() * imgs.size(0)
            correct += (logits.argmax(1) == labels).sum().item()
            total += imgs.size(0)
            pbar.set_postfix(loss=total_loss / total, acc=100.0 * correct / total)

    torch.save({
        "model_state_dict": model.state_dict(),
        "classes": dataset.classes
    }, save_path)
    print(f"saved to {save_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", required=True)
    parser.add_argument("--save_path", default="dataset/model.pt")
    parser.add_argument("--epochs", type=int, default=10)
    args = parser.parse_args()
    Path(os.path.dirname(args.save_path)).mkdir(parents=True, exist_ok=True)
    train(args.data_dir, args.save_path, epochs=args.epochs)