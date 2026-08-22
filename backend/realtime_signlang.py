import cv2
import mediapipe as mp
import numpy as np
from tensorflow.keras.models import load_model
from collections import deque, Counter
import traceback
import json

MODEL_PATH = "signlang_v2_model.keras"
LABELS_PATH = "label_classes.npy"

EXPECTED_FEATURES = 126
WINDOW_SIZE = 8
SHARED_FILE = "latest_prediction.json"

print("Loading model...")

try:
    model = load_model(MODEL_PATH, compile=False)
    print("Model loaded.")
    print("Input shape:", model.input_shape)
except Exception:
    traceback.print_exc()
    exit()

labels = np.load(LABELS_PATH, allow_pickle=True)
print("Labels:", len(labels))

mp_hands = mp.solutions.hands
mp_draw = mp.solutions.drawing_utils

hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.6,
    min_tracking_confidence=0.6
)

prediction_window = deque(maxlen=WINDOW_SIZE)


def save_prediction(label, confidence):

    with open(SHARED_FILE, "w") as f:
        json.dump(
            {
                "label": label,
                "confidence": float(confidence)
            },
            f
        )


def extract_features(results):

    features = []

    if results.multi_hand_landmarks:

        for hand_landmarks in results.multi_hand_landmarks:

            for lm in hand_landmarks.landmark:
                features.extend([lm.x, lm.y, lm.z])

            # Only first hand
            break

    while len(features) < EXPECTED_FEATURES:
        features.append(0.0)

    return np.array(features[:EXPECTED_FEATURES], dtype=np.float32)


cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("Camera failed.")
    exit()

print("Camera started.")

while True:

    ret, frame = cap.read()

    if not ret:
        break

    frame = cv2.flip(frame, 1)

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    results = hands.process(rgb)

    if results.multi_hand_landmarks:

        for hand_landmarks in results.multi_hand_landmarks:

            mp_draw.draw_landmarks(
                frame,
                hand_landmarks,
                mp_hands.HAND_CONNECTIONS
            )

        features = extract_features(results)

        X = features.reshape(1, EXPECTED_FEATURES)

        prediction = model.predict(X, verbose=0)

        idx = np.argmax(prediction)

        confidence = float(np.max(prediction))
        if confidence < 0.75:
            label = "Unknown"
        else:
            label = labels[idx]

        label = labels[idx]

        prediction_window.append(label)

        stable = Counter(prediction_window).most_common(1)[0][0]

        save_prediction(stable, confidence)

        cv2.putText(
            frame,
            f"{stable} ({confidence:.2f})",
            (20, 45),
            cv2.FONT_HERSHEY_SIMPLEX,
            1,
            (0, 255, 0),
            2
        )

    else:

        prediction_window.clear()

        save_prediction(None, 0.0)

    cv2.imshow("Sign Language Detection", frame)

    key = cv2.waitKey(1)

    if key == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()