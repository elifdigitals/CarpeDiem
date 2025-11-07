import os
import argparse
from pathlib import Path
import torch
from torch.utils.data import DataLoader
from torchvision import transforms, datasets
import torch.nn as nn
import torch.optim as optim
from tqdm import tqdm
from face_recognation.model import FaceClassifier



def train(data_dir: str, save_path: str, epochs: int = 10, batch_size: int = 32, lr: float = 1e-4, device: str = None):
    device = device or ("cuda" if torch.cuda.is_available() else "cpu")
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.RandomHorizontalFlip(),
        transforms.ColorJitter(0.1,0.1,0.1,0.1),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225]),
    ])
    dataset = datasets.ImageFolder(data_dir, transform=transform)
    num_classes = len(dataset.classes)
    print(f"Found {len(dataset)} images, {num_classes} classes.")
    loader = DataLoader(dataset, batch_size=batch_size, shuffle=True, num_workers=4, pin_memory=True)

    model = FaceClassifier(num_classes=num_classes, pretrained=True)
    model = model.to(device)

    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=lr)
    scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=5, gamma=0.5)

    for epoch in range(1, epochs+1):
        model.train()
        total_loss = 0.0
        correct = 0
        total = 0
        pbar = tqdm(loader, desc=f"Epoch {epoch}/{epochs}")
        for imgs, labels in pbar:
            imgs = imgs.to(device)
            labels = labels.to(device)
            optimizer.zero_grad()
            logits = model(imgs)
            loss = criterion(logits, labels)
            loss.backward()
            optimizer.step()

            total_loss += loss.item() * imgs.size(0)
            _, preds = logits.max(1)
            correct += (preds == labels).sum().item()
            total += imgs.size(0)
            pbar.set_postfix(loss=total_loss/total, acc=100.0*correct/total)
        scheduler.step()
        epoch_loss = total_loss / total
        epoch_acc = 100.0 * correct / total
        print(f"Epoch {epoch} finished. Loss={epoch_loss:.4f} Acc={epoch_acc:.2f}%")
        ckpt = {
            "model_state_dict": model.state_dict(),
            "classes": dataset.classes,
            "epoch": epoch,
            "optimizer_state_dict": optimizer.state_dict()
        }
        torch.save(ckpt, f"{save_path}.epoch{epoch}.pt")
    torch.save({
        "model_state_dict": model.state_dict(),
        "classes": dataset.classes
    }, "dataset/model.pt")
    print("Training complete. Model saved to", save_path)



if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", type=str, required=True, help="Path to dataset folder (ImageFolder format)")
    parser.add_argument("--save_path", type=str, default="dataset/model.pt")
    parser.add_argument("--epochs", type=int, default=10)
    parser.add_argument("--batch_size", type=int, default=32)
    parser.add_argument("--lr", type=float, default=1e-4)
    args = parser.parse_args()
    Path(os.path.dirname(args.save_path) or ".").mkdir(parents=True, exist_ok=True)
    train(args.data_dir, args.save_path, epochs=args.epochs, batch_size=args.batch_size, lr=args.lr)
