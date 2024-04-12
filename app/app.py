#!/usr/bin/env python
import os

from flask import Flask

app = Flask(__name__)


@app.route('/')
def base():
    return "hello world"

@app.route('/readiness')
def readiness():
    status = {"status": "green"}
    return status

@app.route('/liveness')
def liveness():
    status = {"status": "green"}
    return status


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=os.environ.get("FLASK_SERVER_PORT", 9090), debug=True)
