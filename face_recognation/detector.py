# face_recognition/detector.py
from io import BytesIO
from typing import List, Tuple, Optional
from PIL import Image
import numpy as np
import face_recognition  

def load_image(image_bytes: bytes) -> np.ndarray:
    return face_recognition.load_image_file(BytesIO(image_bytes))

def detect_faces(image: np.ndarray, model: str = "hog", upsample: int = 1):
    return face_recognition.face_locations(
        image,
        number_of_times_to_upsample=upsample,
        model=model
    )

def extract_face(image_bytes: bytes, model: str = "hog"):
    image = load_image(image_bytes)
    locations = detect_faces(image, model=model)
    if not locations:
        return None

    pil_img = Image.fromarray(image)
    top, right, bottom, left = locations[0]
    return pil_img.crop((left, top, right, bottom))

def encode_face(image_bytes: bytes, model: str = "hog") -> Optional[np.ndarray]:
    image = load_image(image_bytes)
    locations = detect_faces(image, model=model)
    encodings = face_recognition.face_encodings(image, known_face_locations=locations)
    return encodings[0] if encodings else None

def compare_faces(known_encodings, unknown_encoding, tolerance=0.6):
    return face_recognition.compare_faces(known_encodings, unknown_encoding, tolerance)
