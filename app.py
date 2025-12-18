from flask import Flask
import os

app = Flask(__name__)

# Simple check to demonstrate environment variables/configuration
VERSION = os.environ.get("APP_VERSION", "1.0.0")

@app.route('/')
def hello_world():
    return f'<h1>Recent Key Results</h1><p>Manchester United 4–4 Bournemouth: A chaotic thriller at Old Trafford on Monday night that saw United drop points despite a high-scoring display.</p>''

if __name__ == '__main__':
    # Host 0.0.0.0 makes it accessible outside the container
    app.run(debug=True, host='0.0.0.0', port=5000)