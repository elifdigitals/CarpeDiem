import sys
import os

print("Before cleanup:")
for path in sys.path:
    print(f"  {path}")

# Удаляем системные пути Python 3.14
sys.path = [p for p in sys.path if "Python314" not in p]

print("\nAfter cleanup:")
for path in sys.path:
    print(f"  {path}")

# Проверяем используемый Python
print(f"\nPython executable: {sys.executable}")
print(f"Python version: {sys.version}")