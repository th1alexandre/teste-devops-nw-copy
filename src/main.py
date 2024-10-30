import subprocess

from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def read_root():
    return jsonify({"message": "Hello, New Way... 2!"})

@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200  # Explicitly set 200 status code

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
