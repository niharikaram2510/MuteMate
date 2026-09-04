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
import csv
import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
# ===============================================================
# AUTHENTICATION DATABASE
# ===============================================================

DATABASE = "users.db"


def init_db():
    conn = sqlite3.connect(DATABASE)

    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
        )
    """)

    conn.commit()
    conn.close()


init_db()

CORS(app, resources={r"/*": {"origins": "*"}})

print("\n✅ Flask starting...", flush=True)


# ===============================================================
# Load Model and Labels
# ===============================================================

try:
    print("⏳ Loading model...", flush=True)

    model = load_model(
        "signlang_v3_model.keras",
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
# REAL-WORLD TRAINING SAMPLE COLLECTION
# ===============================================================

COLLECTION_DIR = "webcam_training_data"
os.makedirs(COLLECTION_DIR, exist_ok=True)
collection_active = False
collection_label = None
collection_count = 0
MAX_SAMPLES_PER_SESSION = 100

VALID_COLLECTION_LABELS = {
    'A','B','BYE','C','D','E','F','G','H','HELLO','HOW ARE YOU','I',
    'I LOVE YOU','J','K','L','M','N','O','P','Q','R','S','SORRY','T',
    'THANK YOU','U','V','W','WELCOME','X','Y','Z'
}


# ===============================================================
# Home
# ===============================================================

@app.route('/')
def home():

    return jsonify({
        "message": "✅ Backend running!"
    })



# ===============================================================
# REGISTER
# ===============================================================

@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json(silent=True) or {}

        email = data.get("email", "").strip().lower()
        password = data.get("password", "")

        if not email or not password:
            return jsonify({
                "success": False,
                "message": "Email and password are required."
            }), 400

        if len(password) < 4:
            return jsonify({
                "success": False,
                "message": "Password must be at least 4 characters."
            }), 400

        password_hash = generate_password_hash(password)

        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()

        try:
            cursor.execute(
                """
                INSERT INTO users (email, password)
                VALUES (?, ?)
                """,
                (email, password_hash)
            )
            conn.commit()
        except sqlite3.IntegrityError:
            conn.close()
            return jsonify({
                "success": False,
                "message": "An account with this email already exists."
            }), 409

        conn.close()

        print(f"✅ New user registered: {email}", flush=True)

        return jsonify({
            "success": True,
            "message": "Account created successfully."
        }), 201

    except Exception as e:
        print("❌ Registration error:", e, flush=True)
        traceback.print_exc()

        return jsonify({
            "success": False,
            "message": "Something went wrong while creating the account."
        }), 500


# ===============================================================
# LOGIN
# ===============================================================

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json(silent=True) or {}

        email = data.get("email", "").strip().lower()
        password = data.get("password", "")

        if not email or not password:
            return jsonify({
                "success": False,
                "message": "Email and password are required."
            }), 400

        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT id, email, password
            FROM users
            WHERE email = ?
            """,
            (email,)
        )

        user = cursor.fetchone()
        conn.close()

        if user is None:
            return jsonify({
                "success": False,
                "message": "Invalid email or password."
            }), 401

        user_id, user_email, password_hash = user

        if not check_password_hash(password_hash, password):
            return jsonify({
                "success": False,
                "message": "Invalid email or password."
            }), 401

        print(f"✅ Login successful: {email}", flush=True)

        return jsonify({
            "success": True,
            "message": "Login successful.",
            "user": {
                "id": user_id,
                "email": user_email
            }
        }), 200

    except Exception as e:
        print("❌ Login error:", e, flush=True)
        traceback.print_exc()

        return jsonify({
            "success": False,
            "message": "Something went wrong while logging in."
        }), 500


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
# COLLECTOR UI
# ===============================================================

@app.route('/collector', methods=['GET'])
def collector():

    labels_for_ui = [
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
        'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
        'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
        'HELLO', 'BYE', 'HOW ARE YOU', 'I LOVE YOU',
        'SORRY', 'THANK YOU', 'WELCOME'
    ]

    buttons = "".join(
        f'<button onclick="startCollection({label!r})">{label}</button>'
        for label in labels_for_ui
    )

    return f"""
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>MuteMate Sample Collector</title>
<style>
body {{
    font-family: Arial, sans-serif;
    max-width: 900px;
    margin: 40px auto;
    padding: 0 20px;
    background: #f6f7fb;
    color: #171923;
}}
h1 {{ margin-bottom: 8px; }}
.subtitle {{ color: #666; margin-bottom: 25px; }}
.status {{
    background: white;
    border-radius: 14px;
    padding: 20px;
    margin-bottom: 20px;
    box-shadow: 0 2px 10px rgba(0,0,0,.08);
}}
#status {{ font-size: 20px; font-weight: bold; }}
#count {{ margin-top: 8px; color: #555; }}
.grid {{
    display: grid;
    grid-template-columns: repeat(6, 1fr);
    gap: 10px;
}}
button {{
    border: 0;
    border-radius: 10px;
    padding: 14px 8px;
    background: #7c3aed;
    color: white;
    font-size: 16px;
    font-weight: bold;
    cursor: pointer;
}}
button:hover {{ opacity: .9; }}
.stop {{
    margin-top: 20px;
    background: #e3344b;
    width: 100%;
}}
.note {{
    margin-top: 20px;
    background: #fff7e6;
    padding: 15px;
    border-radius: 10px;
    color: #6b4b00;
}}
</style>
</head>
<body>

<h1>MuteMate — Real-World Sample Collector</h1>
<div class="subtitle">Collect 100 real webcam/MediaPipe samples for each sign.</div>

<div class="status">
    <div id="status">No collection running</div>
    <div id="count">0 / {MAX_SAMPLES_PER_SESSION}</div>
</div>

<div class="grid">
    {buttons}
</div>

<button class="stop" onclick="stopCollection()">Stop Collection</button>

<div class="note">
    Keep the MuteMate Live Translation camera page open in another tab.
    This page controls collection; the live camera page sends frames to Flask.
</div>

<script>
async function startCollection(label) {{
    const response = await fetch(
        '/start_collection?label=' + encodeURIComponent(label)
    );
    const data = await response.json();

    if (!response.ok) {{
        alert(data.error || 'Could not start collection');
        return;
    }}

    updateStatus(data);
}}

async function stopCollection() {{
    const response = await fetch('/stop_collection');
    const data = await response.json();
    updateStatus(data);
}}

async function refreshStatus() {{
    const response = await fetch('/collection_status');
    const data = await response.json();
    updateStatus(data);
}}

function updateStatus(data) {{
    if (data.collection_active) {{
        document.getElementById('status').textContent =
            'Collecting: ' + data.label;
    }} else {{
        document.getElementById('status').textContent =
            data.label
                ? 'Finished: ' + data.label
                : 'No collection running';
    }}

    document.getElementById('count').textContent =
        (data.count || 0) + ' / ' + (data.target || {MAX_SAMPLES_PER_SESSION});
}}

setInterval(refreshStatus, 500);
refreshStatus();
</script>

</body>
</html>
"""

# ===============================================================
# START TRAINING SAMPLE COLLECTION
# ===============================================================

@app.route('/start_collection', methods=['GET'])
def start_collection():
    global collection_active, collection_label, collection_count
    label = request.args.get("label", "").strip()
    if not label:
        return jsonify({"error":"Missing label. Example: /start_collection?label=HELLO"}), 400
    if label not in VALID_COLLECTION_LABELS:
        return jsonify({"error":f"Invalid label: {label}", "valid_labels":sorted(VALID_COLLECTION_LABELS)}), 400
    collection_label = label

    label_dir = os.path.join(
        COLLECTION_DIR,
        collection_label
    )

    os.makedirs(
        label_dir,
        exist_ok=True
    )

    existing_samples = [
        name for name in os.listdir(label_dir)
        if name.startswith("sample_") and name.endswith(".npy")
    ]

    collection_count = len(existing_samples)
    collection_active = True
    print(f"\n🟢 SAMPLE COLLECTION STARTED: {collection_label}", flush=True)
    return jsonify({"collection_active":True,"label":collection_label,"count":collection_count,"target":MAX_SAMPLES_PER_SESSION})


# ===============================================================
# STOP TRAINING SAMPLE COLLECTION
# ===============================================================

@app.route('/stop_collection', methods=['GET'])
def stop_collection():
    global collection_active, collection_label
    previous_label = collection_label
    collection_active = False
    collection_label = None
    print(f"\n🟥 SAMPLE COLLECTION STOPPED: {previous_label}", flush=True)
    return jsonify({"collection_active":False,"label":previous_label,"count":collection_count})


# ===============================================================
# COLLECTION STATUS
# ===============================================================

@app.route('/collection_status', methods=['GET'])
def collection_status():
    return jsonify({"collection_active":collection_active,"label":collection_label,"count":collection_count,"target":MAX_SAMPLES_PER_SESSION})


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


        # =======================================================
        # COLLECT REAL-WORLD TRAINING SAMPLE
        # =======================================================

        global collection_active, collection_label, collection_count

        if collection_active and collection_label and collection_count < MAX_SAMPLES_PER_SESSION:
            label_dir = os.path.join(COLLECTION_DIR, collection_label)
            os.makedirs(label_dir, exist_ok=True)
            sample_path = os.path.join(label_dir, f"sample_{collection_count:04d}.npy")
            np.save(sample_path, features_array)
            collection_count += 1
            print(f"📸 Collected {collection_label}: {collection_count}/{MAX_SAMPLES_PER_SESSION}", flush=True)
            if collection_count >= MAX_SAMPLES_PER_SESSION:
                collection_active = False
                print(f"\n✅ Finished collecting {MAX_SAMPLES_PER_SESSION} samples for {collection_label}", flush=True)

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