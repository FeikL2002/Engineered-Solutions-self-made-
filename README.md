# Engineered Solutions | Computer Vision & Network Automation

Personal software experiments by **Lewis Joseph Feik**. This repository currently contains two project areas: a macOS-oriented computer-vision prototype and a WireGuard client-management script.

Each project explores a different part of building useful systems: processing camera frames, presenting observations through an interface, storing results, and automating repeatable network-administration tasks.

## Project map

| Project | Purpose | Current state |
|---|---|---|
| [VisionCore](camera-ai/Visioncore/) | Webcam object detection, face detection, dominant-color analysis, and a separate browser/voice experiment. | Standalone camera scripts are present. The Flask prototype has incomplete frontend packaging. |
| [WireGuard client setup](vpn%20Lewy-setup/scripts/) | Create a client profile and add its peer to an existing WireGuard server configuration. | `add-client.sh` is committed. The server installer described in the older project notes is absent. |

## VisionCore

### What is included

- [`vision_core.py`](camera-ai/Visioncore/vision_core.py): a desktop camera loop using OpenCV, NumPy, and Ultralytics YOLO. It overlays object detections, Haar-cascade face boxes, dominant color, and a calculated frame rate. Press **q** to exit its preview window.
- [`camera_test.py`](camera-ai/Visioncore/camera_test.py): a small webcam-preview check.
- [`app.py`](camera-ai/Visioncore/app.py): a Flask experiment with a video stream, JSON detection/statistics routes, SQLite detection logging, text-to-speech, video recording, and requests to a local LM Studio endpoint.
- A YOLO model-weight file and a historical SQLite database are present in the current tree.

The source uses OpenCV's **AVFoundation camera backend**, making macOS the intended platform for the main vision scripts. Other platforms need an appropriate camera-backend adjustment.

### Run the standalone vision prototype

Use a camera you control and grant camera permission to the terminal or Python application when your operating system requests it.

```bash
git clone https://github.com/FeikL2002/Engineered-Solutions-self-made-.git
cd Engineered-Solutions-self-made-/camera-ai/Visioncore
python3 -m venv .venv
source .venv/bin/activate
python -m pip install opencv-python numpy ultralytics
python vision_core.py
```

These dependencies are identified from the source imports. Versions are not pinned in the repository, and this documentation update did not validate a fresh installation or physical camera behavior.

### Flask prototype status

`app.py` also imports Flask, Requests, and pyttsx3. Its language-model request targets `http://localhost:1234/v1/chat/completions`; the configured local model and server must be supplied by the operator.

The current tree does **not** include the `templates/index.html` file required by its `/` route. The app also binds to all network interfaces on port `5050` and contains no authentication layer. Complete the frontend packaging and review its network exposure before treating it as a usable shared dashboard. The source's repeated-detection counter is an experiment, not a validated anomaly-detection system.

## WireGuard client-management script

[`add-client.sh`](vpn%20Lewy-setup/scripts/add-client.sh) accepts a client name and an optional server endpoint. It validates the name, selects an unused address in its configured subnet, generates WireGuard key material, adds a peer, reloads the interface, and writes a client configuration with restrictive file permissions. QR-code output is attempted for mobile import.

The script expects an **already configured Linux WireGuard server** with:

- `/etc/wireguard/wg0.conf` and `/etc/wireguard/server_public.key`;
- the WireGuard tools and Linux network/service utilities used by the script;
- root privileges, plus `qrencode` for QR-code output.

Review the script's subnet, DNS, endpoint, routing, and service assumptions against the server before running it. It changes server configuration and generates private client credentials, which must remain private.

The [older VPN notes](vpn%20Lewy-setup/scripts/README-VPN.md) describe a larger WireGuard/AdGuard Home design. Their referenced `setup-server.sh` and security-notes file are not committed, so the current repository provides client management rather than a complete server installer.

## Scope and development status

These are exploratory projects with platform-specific assumptions. This README describes the committed source and its packaging gaps; it does not claim a verified production deployment. No automated test suite or repository-wide dependency lockfile is currently included.

## Related work

- [Hocking College networking and cybersecurity portfolio](https://github.com/FeikL2002/HockingCollege)
- [Web application security labs](https://github.com/FeikL2002/Web-App-Penetration-Testing)
- [AmericanSites website projects](https://github.com/FeikL2002/AmericanSites.us)
