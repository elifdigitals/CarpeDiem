from io import BytesIO
from typing import List, Tuple, Optional
from PIL import Image
import numpy as np
import face_recognation


def detect_faces(
    image_bytes: bytes,
    model: str = "hog",
    upsample: int = 1
) -> List[Tuple[int, int, int, int]]:
    image = face_recognition.load_image_file(BytesIO(image_bytes))
    face_locations = face_recognition.face_locations(
        image,
        number_of_times_to_upsample=upsample,
        model=model
    )
    return face_locations


def extract_faces(
    image_bytes: bytes,
    model: str = "hog"
) -> List[Image.Image]:
    image = face_recognition.load_image_file(BytesIO(image_bytes))
    face_locations = detect_faces(image_bytes, model=model)
    pil_image = Image.fromarray(image)

    faces = []
    for (top, right, bottom, left) in face_locations:
        face = pil_image.crop((left, top, right, bottom))
        faces.append(face)
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
    image = face_recognition.load_image_file(BytesIO(image_bytes))
    encodings = face_recognition.face_encodings(image, model=model)
    if len(encodings) == 0:
        return None
    return encodings[0]


def compare_faces(
    known_encodings: List[np.ndarray],
    unknown_encoding: np.ndarray,
    tolerance: float = 0.6
) -> List[bool]:
    return face_recognition.compare_faces(known_encodings, unknown_encoding, tolerance)
