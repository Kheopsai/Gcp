#!/bin/bash

# Define the host and port
HOST="0.0.0.0"
PORT="80"

# Run the Python HTTP server
echo "Starting Python HTTP server on $HOST:$PORT..."
python3 - <<EOF
from http.server import BaseHTTPRequestHandler, HTTPServer

class HelloWorldHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Send HTTP status 200 (OK)
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        # Write the response body
        self.wfile.write(b"Hello, World 3!")

# Configure and start the server
server = HTTPServer(("$HOST", $PORT), HelloWorldHandler)
print(f"Serving HTTP on $HOST:$PORT...")
server.serve_forever()
EOF
