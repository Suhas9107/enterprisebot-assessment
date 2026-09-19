import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

APP_NAME = os.getenv("APP_NAME", "demo-service")
VERSION = os.getenv("VERSION", "0.1.0")

@app.get("/")
def root():
    return jsonify({
        "app": APP_NAME,
        "version": VERSION,
        "pod": socket.gethostname(),
    })

@app.get("/healthz")
def healthz():
    return jsonify({"status": "healthy"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
