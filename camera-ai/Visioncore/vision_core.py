import cv2
import numpy as np
from ultralytics import YOLO
import time

# SETTINGS
USE_YOLO = True
USE_FACE = True
USE_COLOR = True

# Load YOLO
if USE_YOLO:
    print("Loading YOLO...")
    yolo_model = YOLO("yolov8n.pt")
    print("YOLO Loaded.")

# Load Face Detector
if USE_FACE:
    face_cascade = cv2.CascadeClassifier(
        cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    )

# Dominant color function
def get_dominant_color(frame):
    data = np.reshape(frame, (-1, 3))
    data = np.float32(data)
    _, labels, centers = cv2.kmeans(
        data, 1, None,
        (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 10, 1.0),
        10,
        cv2.KMEANS_RANDOM_CENTERS
    )
    return centers[0]

# Start camera (Mac backend)
cap = cv2.VideoCapture(0, cv2.CAP_AVFOUNDATION)

if not cap.isOpened():
    print("Error: Could not open webcam.")
    exit()

prev_time = time.time()

while True:
    ret, frame = cap.read()
    if not ret:
        print("Failed to grab frame.")
        break

    display_frame = frame.copy()
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # YOLO detection
    if USE_YOLO:
        results = yolo_model(frame, verbose=False)
        display_frame = results[0].plot()

    # Face detection
    if USE_FACE:
        faces = face_cascade.detectMultiScale(gray, 1.3, 5)
        for (x, y, w, h) in faces:
            cv2.rectangle(display_frame, (x, y), (x+w, y+h), (255, 0, 0), 2)

    # Color analysis
    if USE_COLOR:
        color = get_dominant_color(frame)
        cv2.putText(
            display_frame,
            f"Dominant Color: {color.astype(int)}",
            (10, 30),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (0, 255, 255),
            2
        )

    # FPS calculation (fixed)
    current_time = time.time()
    fps = 1 / (current_time - prev_time)
    prev_time = current_time

    cv2.putText(
        display_frame,
        f"FPS: {int(fps)}",
        (10, 60),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.6,
        (0, 255, 0),
        2
    )

    cv2.imshow("VisionCore - Mac", display_frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()