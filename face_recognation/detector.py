from io import BytesIO
from typing import List, Tuple, Optional
from PIL import Image
import numpy as np
import face_recognition


def load_image(image_bytes: bytes) -> np.ndarray:
    return face_recognition.load_image_file(BytesIO(image_bytes))


def detect_faces(
    image: np.ndarray,
    model: str = "hog",
    upsample: int = 1
) -> List[Tuple[int, int, int, int]]:
    return face_recognition.face_locations(
        image,
        number_of_times_to_upsample=upsample,
        model=model
    )


def extract_faces(
    image_bytes: bytes,
    model: str = "hog"
) -> List[Image.Image]:
    image = load_image(image_bytes)
    locations = detect_faces(image, model=model)
    pil_image = Image.fromarray(image)

    faces = [pil_image.crop((left, top, right, bottom)) for (top, right, bottom, left) in locations]
    return faces


def extract_single_face(
    image_bytes: bytes,
    model: str = "hog"
) -> Optional[Image.Image]:
    faces = extract_faces(image_bytes, model=model)
    return faces[0] if faces else None


def encode_face(
    image_bytes: bytes,
    model: str = "hog"
) -> Optional[np.ndarray]:
    image = load_image(image_bytes)
    face_locations = detect_faces(image, model=model)
    encodings = face_recognition.face_encodings(image, known_face_locations=face_locations)
    return encodings[0] if encodings else None


def compare_faces(
    known_encodings: List[np.ndarray],
    unknown_encoding: np.ndarray,
    tolerance: float = 0.6
) -> List[bool]:
    return face_recognition.compare_faces(known_encodings, unknown_encoding, tolerance)