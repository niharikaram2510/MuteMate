from flask import Flask, jsonify, request
from flask_cors import CORS
from tensorflow.keras.models import load_model
import numpy as np
import traceback
import sys
import os
import subprocess
import json
import cv2
import mediapipe as mp
from collections import deque, Counter

app = Flask(__name__)

CORS(app, resources={r"/*": {"origins": "*"}})

print("\n✅ Flask starting...", flush=True)


# ===============================================================
# Load Model and Labels
# ===============================================================

try:
    print("⏳ Loading model...", flush=True)

    model = load_model(
        "signlang_v2_model.keras",
        compile=False
    )

    print("✅ Model loaded successfully", flush=True)

except Exception as e:
    print("❌ Failed to load model:", e, flush=True)
    traceback.print_exc()
    model = None


try:
    labels = np.load(
        "label_classes.npy",
        allow_pickle=True
    )

    print(
        f"✅ Labels loaded: {len(labels)} classes",
        flush=True
    )

except Exception as e:
    print("❌ Failed to load labels:", e, flush=True)
    traceback.print_exc()
    labels = None


# ===============================================================
# MediaPipe Setup
# ===============================================================

mp_hands = mp.solutions.hands

hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

EXPECTED_FEATURES = 126


# ===============================================================
# Prediction Stabilization
# ===============================================================

prediction_history = deque(maxlen=8)


# ===============================================================
# Home
# ===============================================================

@app.route('/')
def home():

    return jsonify({
        "message": "✅ Backend running!"
    })


# ===============================================================
# OLD CAMERA ROUTE
# ===============================================================

@app.route('/start_detection', methods=['GET'])
def start_camera():

    try:

        print(
            "🎥 Launching camera in a new process...",
            flush=True
        )

        subprocess.Popen([
            sys.executable,
            "realtime_signlang.py"
        ])

        return jsonify({
            "message": "Camera started successfully!"
        })

    except Exception as e:

        print(
            "❌ Failed to start camera:",
            e,
            flush=True
        )

        return jsonify({
            "error": str(e)
        }), 500


# ===============================================================
# OLD STOP ROUTE
# ===============================================================

@app.route('/stop_detection', methods=['GET'])
def stop_camera():

    try:

        print(
            "🟥 Stop requested — please close the camera window manually (press 'q').",
            flush=True
        )

        return jsonify({
            "message":
            "Please close the camera window manually by pressing 'q'."
        })

    except Exception as e:

        return jsonify({
            "error": str(e)
        }), 500


# ===============================================================
# OLD LIVE PREDICTION ROUTE
# ===============================================================

@app.route('/live', methods=['GET'])
def live_prediction():

    try:

        if not os.path.exists(
            "latest_prediction.json"
        ):

            return jsonify({
                "prediction": None,
                "confidence": 0.0
            })

        with open(
            "latest_prediction.json",
            "r"
        ) as f:

            data = json.load(f)

        if not data or "label" not in data:

            return jsonify({
                "prediction": None,
                "confidence": 0.0
            })

        return jsonify({

            "prediction":
            data["label"],

            "confidence":
            data["confidence"]

        })

    except Exception as e:

        print(
            "⚠️ Error reading shared file:",
            e
        )

        return jsonify({
            "prediction": None,
            "confidence": 0.0
        })


# ===============================================================
# BROWSER FRAME → AI PREDICTION
# ===============================================================

@app.route('/predict_frame', methods=['POST'])
def predict_frame():

    try:

        # -------------------------------------------------------
        # Check model and labels
        # -------------------------------------------------------

        if model is None or labels is None:

            return jsonify({
                "prediction": None,
                "confidence": 0.0,
                "error": "Model or labels not loaded"
            }), 500


        # -------------------------------------------------------
        # Check uploaded frame
        # -------------------------------------------------------

        if 'frame' not in request.files:

            return jsonify({
                "prediction": None,
                "confidence": 0.0,
                "error": "No frame received"
            }), 400


        # -------------------------------------------------------
        # Read uploaded image
        # -------------------------------------------------------

        file = request.files['frame']

        image_bytes = file.read()

        np_arr = np.frombuffer(
            image_bytes,
            np.uint8
        )

        frame = cv2.imdecode(
            np_arr,
            cv2.IMREAD_COLOR
        )

        if frame is None:

            return jsonify({
                "prediction": None,
                "confidence": 0.0,
                "error": "Could not decode frame"
            }), 400


        # =======================================================
        # MATCH TRAINING PREPROCESSING
        # =======================================================

        frame = cv2.flip(frame, 1)


        # -------------------------------------------------------
        # BGR → RGB
        # -------------------------------------------------------

        rgb = cv2.cvtColor(
            frame,
            cv2.COLOR_BGR2RGB
        )


        # -------------------------------------------------------
        # MediaPipe hand detection
        # -------------------------------------------------------

        results = hands.process(rgb)


        # -------------------------------------------------------
        # No hands detected
        # -------------------------------------------------------

        if not results.multi_hand_landmarks:

            prediction_history.clear()

            return jsonify({

                "prediction": None,

                "confidence": 0.0,

                "hand_detected": False,

                "hands_detected": 0

            })


        # =======================================================
        # HAND INFORMATION
        # =======================================================

        detected_hands = len(
            results.multi_hand_landmarks
        )

        handedness_names = []

        if results.multi_handedness:

            for handedness in results.multi_handedness:

                handedness_names.append(
                    handedness.classification[0].label
                )


        # =======================================================
        # EXTRACT 126 FEATURES
        #
        # IMPORTANT:
        # Keep the SAME ordering as the training extractor.
        # We are NOT reordering hands here.
        # =======================================================

        features = []


        for hand_landmarks in results.multi_hand_landmarks:

            for lm in hand_landmarks.landmark:

                features.extend([
                    lm.x,
                    lm.y,
                    lm.z
                ])


        # -------------------------------------------------------
        # If only one hand is detected,
        # pad second hand with zeros.
        # -------------------------------------------------------

        if detected_hands == 1:

            features.extend(
                [0.0] * (21 * 3)
            )


        # -------------------------------------------------------
        # Ensure exactly 126 features
        # -------------------------------------------------------

        while len(features) < EXPECTED_FEATURES:

            features.append(0.0)


        features = features[
            :EXPECTED_FEATURES
        ]


        # =======================================================
        # DEBUG: SAVE LIVE FEATURES
        # =======================================================

        features_array = np.array(
            features,
            dtype=np.float32
        )

        np.save(
            "latest_live_features.npy",
            features_array
        )


        # =======================================================
        # DEBUG: SAVE PROCESSED FRAME
        # =======================================================

        cv2.imwrite(
            "latest_live_frame.jpg",
            frame
        )


        # =======================================================
        # DEBUG: SAVE MEDIAPIPE LANDMARKS
        # =======================================================

        landmarks_data = []

        for hand_index, hand_landmarks in enumerate(
            results.multi_hand_landmarks
        ):

            hand_name = (
                handedness_names[hand_index]
                if hand_index < len(handedness_names)
                else "Unknown"
            )

            hand_data = {
                "hand_index": hand_index,
                "handedness": hand_name,
                "landmarks": []
            }

            for landmark_index, lm in enumerate(
                hand_landmarks.landmark
            ):

                hand_data["landmarks"].append({
                    "index": landmark_index,
                    "x": float(lm.x),
                    "y": float(lm.y),
                    "z": float(lm.z)
                })

            landmarks_data.append(hand_data)


        with open(
            "latest_live_landmarks.json",
            "w"
        ) as f:

            json.dump(
                landmarks_data,
                f,
                indent=2
            )


        # -------------------------------------------------------
        # Convert to model input
        # -------------------------------------------------------

        X = features_array.reshape(
            1,
            EXPECTED_FEATURES
        )


        # =======================================================
        # MODEL PREDICTION
        # =======================================================

        prediction = model.predict(
            X,
            verbose=0
        )


        idx = int(
            np.argmax(prediction)
        )

        confidence = float(
            np.max(prediction)
        )

        raw_label = str(
            labels[idx]
        )


        # =======================================================
        # CONFIDENCE + PREDICTION STABILIZATION
        # =======================================================

        if confidence < 0.75:

            prediction_history.clear()

            label = "Unknown"

        else:

            prediction_history.append(
                raw_label
            )

            if len(prediction_history) >= 4:

                counts = Counter(
                    prediction_history
                )

                stable_label, stable_count = (
                    counts.most_common(1)[0]
                )

                if stable_count >= 4:

                    label = stable_label

                else:

                    label = "Unknown"

            else:

                label = "Unknown"


        # =======================================================
        # DEBUG INFORMATION
        # =======================================================

        print(
            f"🤖 Prediction: {label} | "
            f"Raw: {raw_label} | "
            f"Confidence: {confidence:.3f} | "
            f"Hands: {detected_hands} | "
            f"Types: {handedness_names} | "
            f"History: {list(prediction_history)}",
            flush=True
        )

        print(
            f"💾 Saved {len(features_array)} live features",
            flush=True
        )


        # -------------------------------------------------------
        # Return result
        # -------------------------------------------------------

        return jsonify({

            "prediction": label,

            "confidence": confidence,

            "hand_detected": True,

            "hands_detected": detected_hands,

            "handedness": handedness_names

        })


    except Exception as e:

        print(
            "⚠️ Prediction error:",
            e,
            flush=True
        )

        traceback.print_exc()


        return jsonify({

            "prediction": None,

            "confidence": 0.0,

            "hand_detected": False,

            "error": str(e)

        }), 500


# ===============================================================
# Main Entry
# ===============================================================

if __name__ == '__main__':

    print(
        "\n🚀 Starting Flask server...",
        flush=True
    )

    app.run(
        host='0.0.0.0',
        port=5000,
        debug=False
    )