from flask import Flask, jsonify
from flask_cors import CORS
from tensorflow.keras.models import load_model
import numpy as np
import traceback
import sys
import os
import subprocess
import json

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

print("\n✅ Flask starting...", flush=True)

# -------------------- Load Model and Labels --------------------
try:
    print("⏳ Loading model...", flush=True)
    model = load_model("signlang_v2_model.keras", compile=False)
    print("✅ Model loaded successfully", flush=True)
except Exception as e:
    print("❌ Failed to load model:", e, flush=True)
    traceback.print_exc()
    model = None

try:
    labels = np.load("label_classes.npy", allow_pickle=True)
    print(f"✅ Labels loaded: {len(labels)} classes", flush=True)
except Exception as e:
    print("❌ Failed to load labels:", e, flush=True)
    traceback.print_exc()
    labels = None
# ---------------------------------------------------------------


@app.route('/')
def home():
    return jsonify({"message": "✅ Backend running!"})


# 🎥 Start camera (launches realtime_signlang.py in new process)
@app.route('/start_detection', methods=['GET'])
def start_camera():
    try:
        print("🎥 Launching camera in a new process...", flush=True)
        subprocess.Popen([sys.executable, "realtime_signlang.py"])
        return jsonify({"message": "Camera started successfully!"})
    except Exception as e:
        print("❌ Failed to start camera:", e, flush=True)
        return jsonify({"error": str(e)}), 500


# 🟥 Stop route (user closes manually)
@app.route('/stop_detection', methods=['GET'])
def stop_camera():
    try:
        print("🟥 Stop requested — please close the camera window manually (press 'q').", flush=True)
        return jsonify({"message": "Please close the camera window manually by pressing 'q'."})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# 🔁 Live prediction (read shared JSON file)
@app.route('/live', methods=['GET'])
def live_prediction():
    try:
        if not os.path.exists("latest_prediction.json"):
            return jsonify({"prediction": None, "confidence": 0.0})

        with open("latest_prediction.json", "r") as f:
            data = json.load(f)

        if not data or "label" not in data:
            return jsonify({"prediction": None, "confidence": 0.0})

        return jsonify({
            "prediction": data["label"],
            "confidence": data["confidence"]
        })
    except Exception as e:
        print("⚠️ Error reading shared file:", e)
        return jsonify({"prediction": None, "confidence": 0.0})
    

# ---------------- Main Entry ----------------
if __name__ == '__main__':
    print("\n🚀 Starting Flask server...", flush=True)
    app.run(host='0.0.0.0', port=5000, debug=False)
