from flask import Flask
import os

app = Flask(__name__)

# Simple check to demonstrate environment variables/configuration
VERSION = os.environ.get("APP_VERSION", "1.0.0")

@app.route('/')
def hello_world():
    return f'<h1>HI I AM MUHAMMAD IBRAHIM AND THIS IS MY DEVOPS PROJECT</h1><p>Version: {VERSION}</p>'

if __name__ == '__main__':
    # Host 0.0.0.0 makes it accessible outside the container
    app.run(debug=True, host='0.0.0.0', port=5000)