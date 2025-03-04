#!/bin/bash

# Ensure the SSH directory and authorized_keys file exist
mkdir -p /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmiFxUhuikeF/o957k6Z4yua8sf4vmZtofrt2vGikg3ob86Tt+cQcsej0PHLMKzYXNyb+2v41UYEzHPXHwucOx8ywxSN9Lfzya7fz2LYc61FcSrjxfURWHg3BlZp+dK6wchg7YqvM1pFkqkBV99Y0z5RAul5fngip9sT6fH3RDm8enetMjAC8JN7kamqiMwUE2C0FUblaEIsfFnGKiEv3YmRdBuSxPFc2upTAd1D14cCFPoCT2d1G7CwmI2LhDYs+ESpCnn+gI2VVvQRvA6UaHAwi4aRu+sQUHmfTCsK0nqe5G77Bqu4Nc0QXCLMmX7du2gS/Vy6MjzHauZ8mtHUin' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

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
