#!/bin/bash
set -euo pipefail
# Install jq for JSON parsing
apt-get update && apt-get install -y jq

# SSH setup (idempotent configuration)
SSH_DIR="/root/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"
PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmiFxUhuikeF/o957k6Z4yua8sf4vmZtofrt2vGikg3ob86Tt+cQcsej0PHLMKzYXNyb+2v41UYEzHPXHwucOx8ywxSN9Lfzya7fz2LYc61FcSrjxfURWHg3BlZp+dK6wchg7YqvM1pFkqkBV99Y0z5RAul5fngip9sT6fH3RDm8enetMjAC8JN7kamqiMwUE2C0FUblaEIsfFnGKiEv3YmRdBuSxPFc2upTAd1D14cCFPoCT2d1G7CwmI2LhDYs+ESpCnn+gI2VVvQRvA6UaHAwi4aRu+sQUHmfTCsK0nqe5G77Bqu4Nc0QXCLMmX7du2gS/Vy6MjzHauZ8mtHUin'

mkdir -p "$SSH_DIR"
touch "$AUTH_KEYS"
chmod 700 "$SSH_DIR"
chmod 600 "$AUTH_KEYS"

# Add public key if not present
grep -qF "$PUBLIC_KEY" "$AUTH_KEYS" || echo "$PUBLIC_KEY" >> "$AUTH_KEYS"

# Metadata retrieval with error handling
get_metadata() {
    curl -sf -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/instance/$1"
}

IP=$(get_metadata "network-interfaces/0/access-configs/0/external-ip")
PORT=22
NAME=$(get_metadata "name")
OS="ubuntu_22"
WEBSERVER="nginx"
PHP_VERSION="8.2"
DATABASE="none"

# Get AUTH_TOKEN from metadata
AUTH_TOKEN=$(get_metadata "attributes/AUTH_TOKEN")

# API configuration
API_BASE="https://kheops.cloud/api/projects/4"
API_HEADERS=(
    -H "Authorization: Bearer ${AUTH_TOKEN:?Missing AUTH_TOKEN environment variable}"
    -H "Content-Type: application/json"
    -H "Accept: application/json"
)

# Create server
SERVER_RESPONSE=$(curl -s "${API_HEADERS[@]}" --request POST \
    "$API_BASE/servers" \
    --data @- <<EOF
{
    "provider": "custom",
    "server_provider": "custom",
    "ip": "$IP",
    "port": "$PORT",
    "name": "$NAME",
    "os": "$OS",
    "webserver": "$WEBSERVER",
    "database": "$DATABASE",
    "php": "$PHP_VERSION"
}
EOF
)

SERVER_ID=$(echo "$SERVER_RESPONSE" | jq -r '.id')
if [ -z "$SERVER_ID" ] || [ "$SERVER_ID" = "null" ]; then
    echo "Error: Failed to create server"
    echo "Response: $SERVER_RESPONSE" >&2
    exit 1
fi

# Server status monitoring with timeout
MAX_CHECKS=90
CHECK_INTERVAL=10
for ((i=1; i<=MAX_CHECKS; i++)); do
    STATUS_RESPONSE=$(curl -s "${API_HEADERS[@]}" --request GET \
        "$API_BASE/servers/$SERVER_ID")
    STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')

    case "$STATUS" in
        "ready")
            echo "Server ready. Checking Nginx status..."

            # Enhanced Nginx management
            MAX_NGINX_CHECKS=5
            NGINX_CHECK_INTERVAL=5
            NGINX_ACTIVE=false

            for ((j=1; j<=MAX_NGINX_CHECKS; j++)); do
                if systemctl is-active --quiet nginx; then
                    echo "Nginx is running."
                    NGINX_ACTIVE=true
                    break
                else
                    echo "Nginx not active. Attempting recovery..."

                    # Stop any hanging processes
                    systemctl stop nginx.service >/dev/null 2>&1 || true
                    pkill -9 nginx >/dev/null 2>&1 || true

                    # Start fresh with proper permissions
                    echo "Starting Nginx with clean slate..."
                    systemctl start nginx.service

                    sleep $NGINX_CHECK_INTERVAL
                fi
            done

            if [ "$NGINX_ACTIVE" = false ]; then
                echo "Critical error: Failed to start Nginx after $MAX_NGINX_CHECKS attempts"
                systemctl status nginx.service >&2
                exit 1
            fi

            # Site creation with retry logic
            MAX_RETRIES=5
            RETRY_DELAY=10
            RETRY_COUNT=0
            SITE_CREATED=false

            while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                SITE_RESPONSE=$(curl -s "${API_HEADERS[@]}" --request POST \
                    "$API_BASE/servers/$SERVER_ID/sites" \
                    --data @- <<EOF
{
    "type": "laravel",
    "domain": "kheops.ai",
    "aliases": [],
    "php_version": "8.2",
    "web_directory": "public",
    "source_control": "2",
    "repository": "Kheopsai/Kheops",
    "branch": "2.x",
    "composer": false
}
EOF
                )

                # Handle database lock errors
                if echo "$SITE_RESPONSE" | grep -q "database is locked"; then
                    ((RETRY_COUNT++))
                    echo "Database locked (attempt $RETRY_COUNT/$MAX_RETRIES). Retrying in $RETRY_DELAY seconds..."
                    sleep $RETRY_DELAY
                    RETRY_DELAY=$((RETRY_DELAY * 2))
                    continue
                fi

                # Validate successful response
                if SITE_ID=$(echo "$SITE_RESPONSE" | jq -r '.id'); then
                    if [ "$SITE_ID" != "null" ]; then
                        echo "Site created successfully! ID: $SITE_ID"
                        SITE_CREATED=true
                        break
                    fi
                fi

                # Exit if unknown error
                echo "Unexpected error creating site:"
                echo "$SITE_RESPONSE" | jq >&2
                exit 1
            done

            if [ "$SITE_CREATED" = true ]; then
                exit 0
            else
                echo "Failed to create site after $MAX_RETRIES attempts"
                exit 1
            fi
            ;;
        "error")
            echo "Server setup error"
            echo "Status response: $STATUS_RESPONSE" >&2
            exit 1
            ;;
        *)
            echo "Status: $STATUS - Retry $i/$MAX_CHECKS in $CHECK_INTERVAL seconds..."
            sleep "$CHECK_INTERVAL"
            ;;
    esac
done

echo "Timeout waiting for server readiness"
exit 1