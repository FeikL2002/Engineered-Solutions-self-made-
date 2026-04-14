import cv2
import sqlite3
import time
import os
import requests
import pyttsx3
from datetime import datetime
from ultralytics import YOLO
from flask import Flask, render_template, Response, jsonify

app = Flask(__name__)

# ------------------------
# SETTINGS
# ------------------------
yolo_enabled = True
face_enabled = True
latest_detections = []
latest_reasoning = ""
detection_counter = {}

# Ensure recordings folder exists
if not os.path.exists("recordings"):
    os.makedirs("recordings")

# ------------------------
# VOICE ENGINE
# ------------------------
engine = pyttsx3.init()

def speak(text):
    engine.say(text)
    engine.runAndWait()

# ------------------------
# DATABASE SETUP
# ------------------------
def init_db():
    conn = sqlite3.connect("vision.db")
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS detections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT,
            timestamp TEXT
        )
    """)
    conn.commit()
    conn.close()

def log_detection(label):
    conn = sqlite3.connect("vision.db")
    c = conn.cursor()
    c.execute(
        "INSERT INTO detections (label, timestamp) VALUES (?, ?)",
        (label, datetime.now().isoformat())
    )
    conn.commit()
    conn.close()

init_db()

# ------------------------
# LOAD MODELS
# ------------------------
yolo_model = YOLO("yolov8n.pt")

face_cascade = cv2.CascadeClassifier(
    cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
)

# ------------------------
# VIDEO STREAM + RECORDING
# ------------------------
def generate_frames():
    global latest_detections, latest_reasoning, detection_counter

    cap = cv2.VideoCapture(0, cv2.CAP_AVFOUNDATION)

    # Force stable resolution for recording
    width = 640
    height = 480

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)

    # Mac-safe H264 codec
    filename = f"recordings/recording_{int(time.time())}.mp4"
    fourcc = cv2.VideoWriter_fourcc(*"avc1")
    out = cv2.VideoWriter(filename, fourcc, 20.0, (width, height))

    print(f"Recording started: {filename}")

    while True:
        success, frame = cap.read()
        if not success:
            break

        detections = []
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # ------------------------
        # YOLO Detection
        # ------------------------
        if yolo_enabled:
            results = yolo_model(frame, verbose=False)
            for r in results:
                for box in r.boxes:
                    cls = int(box.cls[0])
                    label = yolo_model.names[cls]
                    detections.append(label)

            frame = results[0].plot()

        # ------------------------
        # Face Detection
        # ------------------------
        if face_enabled:
            faces = face_cascade.detectMultiScale(gray, 1.3, 5)
            if len(faces) > 0:
                detections.append("face")

        latest_detections = list(set(detections))

        # ------------------------
        # Logging + Voice + Anomaly
        # ------------------------
        for label in latest_detections:
            log_detection(label)

            detection_counter[label] = detection_counter.get(label, 0) + 1

            if detection_counter[label] == 1:
                speak(f"Detected {label}")

            if detection_counter[label] > 15:
                speak(f"Anomaly detected: frequent {label}")
                detection_counter[label] = 0

        # ------------------------
        # LM Studio Reasoning
        # ------------------------
        if latest_detections:
            try:
                response = requests.post(
                    "http://localhost:1234/v1/chat/completions",
                    json={
                        "model": "local-model",
                        "messages": [
                            {
                                "role": "user",
                                "content": f"Explain what is happening if these objects are visible: {latest_detections}"
                            }
                        ]
                    },
                    timeout=2
                )
                latest_reasoning = response.json()["choices"][0]["message"]["content"]
            except:
                latest_reasoning = "LM Studio not connected."

        # ------------------------
        # Record video
        # ------------------------
        out.write(frame)

        # ------------------------
        # Stream frame to browser
        # ------------------------
        ret, buffer = cv2.imencode(".jpg", frame)
        frame_bytes = buffer.tobytes()

        yield (
            b"--frame\r\n"
            b"Content-Type: image/jpeg\r\n\r\n" + frame_bytes + b"\r\n"
        )

    cap.release()
    out.release()
    print("Recording stopped.")

# ------------------------
# ROUTES
# ------------------------
@app.route("/")
def index():
    return render_template("index.html")

@app.route("/video")
def video():
    return Response(
        generate_frames(),
        mimetype="multipart/x-mixed-replace; boundary=frame",
    )

@app.route("/detections")
def detections():
    return jsonify(latest_detections)

@app.route("/reasoning")
def reasoning():
    return jsonify({"reasoning": latest_reasoning})

@app.route("/stats")
def stats():
    conn = sqlite3.connect("vision.db")
    c = conn.cursor()
    c.execute("SELECT label, COUNT(*) FROM detections GROUP BY label")
    data = c.fetchall()
    conn.close()
    return jsonify(data)

@app.route("/toggle/<feature>")
def toggle(feature):
    global yolo_enabled, face_enabled
    if feature == "yolo":
        yolo_enabled = not yolo_enabled
    if feature == "face":
        face_enabled = not face_enabled
    return "OK"

# ------------------------
# START SERVER
# ------------------------
if __name__ == "__main__":
    print("Starting VisionCore on port 5050...")
    app.run(host="0.0.0.0", port=5050, debug=False)