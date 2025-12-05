# save_known_face.py
import numpy as np
from face_recognation.detector import encode_face

KNOWN_IMAGE_PATH = "known_face.jpg"
ENCODING_PATH = "known_face.npy"

def main():
    with open(KNOWN_IMAGE_PATH, "rb") as f:
        img_bytes = f.read()

    encoding = encode_face(img_bytes)

    if encoding is None:
        print("На эталонном фото лицо не найдено!")
        return

    np.save(ENCODING_PATH, encoding)
    print("Encoding сохранён в", ENCODING_PATH)

if __name__ == "__main__":
    main()
