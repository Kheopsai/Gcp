#!/bin/bash
set -euo pipefail

# Force non-interactive installs
export DEBIAN_FRONTEND=noninteractive
APT_OPTS="-y \
  -o Dpkg::Options::=--force-confdef \
  -o Dpkg::Options::=--force-confold \
  --allow-downgrades \
  --allow-remove-essential \
  --allow-change-held-packages"

# Install jq for JSON parsing and other pre-reqs
apt-get update
apt-get install $APT_OPTS jq software-properties-common apt-transport-https \
  ca-certificates curl gnupg unzip git libpng-dev libjpeg-dev libwebp-dev \
  libzip-dev libonig-dev libxml2-dev libxslt1-dev libtidy-dev libicu-dev \
  libmagickwand-dev libpq-dev libssl-dev ffmpeg tesseract-ocr \
  tesseract-ocr-fra tesseract-ocr-eng imagemagick ghostscript poppler-utils \
  libreoffice redis-server memcached postgresql postgresql-contrib

SSH_DIR="/root/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"
PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDV7bVnecDaTps3g1823s+NbxsSgdEVjJYqKqqdhZysAcWBb3nWYBdDjTHCFpf29QDE/z864Nm8vEzRcXNzCLatq9LI8Hu3KJFc5wSWDzNvEyZChyc/qGMLpbJWg9sNvBNuFTKf6g320GDvrOzg+6/PFY60IXSxZnop7r7WznOYzcLQnvVkfuF8TGJ1UHX8+4tnskuwMOoikR5Fi91TZxJ+xD/ghWTAigWsNkXo3U8fZdrQNalRJZtCiZR15gRlQwOLxaMSMAdCpihBthLrE4ymYUaqEesEuvkXzHBDmz4VXXssANU5tH/BjuxrLMc+rhTN4IWbs/o0EwcE4ZEAb9XJ'

mkdir -p "$SSH_DIR"
touch "$AUTH_KEYS"
chmod 700 "$SSH_DIR"
chmod 600 "$AUTH_KEYS"

# Add public key if not present
grep -qF "$PUBLIC_KEY" "$AUTH_KEYS" || echo "$PUBLIC_KEY" >> "$AUTH_KEYS"

# Helper to retrieve GCE metadata
get_metadata() {
    curl -sf -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/instance/$1"
}

# Basic metadata
IP=$(get_metadata "network-interfaces/0/access-configs/0/external-ip")
PORT=22
NAME=$(get_metadata "name")
OS="ubuntu_22"
WEBSERVER="nginx"
PHP_VERSION="8.3"
DATABASE="none"

API_HOST="https://vito.kheops.cloud/api"
AUTH_TOKEN=$(get_metadata "attributes/AUTH_TOKEN")

API_HEADERS=(
    -H "Authorization: Bearer ${AUTH_TOKEN:?Missing AUTH_TOKEN}"
    -H "Content-Type: application/json"
    -H "Accept: application/json"
)

# Retrieve project name and ID
PROJECT_NAME=$(get_metadata "attributes/PROJECT_NAME")
PROJECTS_JSON=$(curl -s "${API_HEADERS[@]}" --request GET "${API_HOST}/projects")

PROJECT_ID=$(echo "$PROJECTS_JSON" | jq -r --arg name "$PROJECT_NAME" \
    '.[] | select(.name == $name) | .id')

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
    echo "Erreur : projet '$PROJECT_NAME' introuvable dans la liste." >&2
    exit 1
fi

echo "→ Projet '$PROJECT_NAME' trouvé avec ID = $PROJECT_ID"

API_BASE="${API_HOST}/projects/${PROJECT_ID}"

# Create server
SERVER_RESPONSE=$(curl -s "${API_HEADERS[@]}" --request POST \
    "$API_BASE/servers" --data @- <<EOF
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

if [[ -z "$SERVER_ID" || "$SERVER_ID" == "null" ]]; then
    echo "Error: Failed to create server" >&2
    echo "Response: $SERVER_RESPONSE" >&2
    exit 1
fi

# Poll server status
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
                    systemctl stop nginx.service >/dev/null 2>&1 || true
                    pkill -9 nginx >/dev/null 2>&1  || true
                    echo "Starting Nginx with clean slate..."
                    systemctl start nginx.service
                    sleep $NGINX_CHECK_INTERVAL
                fi
            done

            if [[ "$NGINX_ACTIVE" != true ]]; then
                echo "Critical error: Failed to start Nginx after $MAX_NGINX_CHECKS attempts" >&2
                systemctl status nginx.service >&2
                exit 1
            fi

            # Site creation with retry logic
            MAX_RETRIES=5
            RETRY_DELAY=10
            RETRY_COUNT=0
            SITE_CREATED=false

            while (( RETRY_COUNT < MAX_RETRIES )); do
                SITE_RESPONSE=$(curl -s "${API_HEADERS[@]}" --request POST \
                    "$API_BASE/servers/$SERVER_ID/sites" \
                    --data @- <<EOF
{
    "type": "laravel",
    "domain": "kheops.site",
    "aliases": [],
    "php_version": "8.3",
    "web_directory": "public",
    "source_control": "1",
    "repository": "Kheopsai/Kheops",
    "branch": "2.x",
    "composer": false
}
EOF
)
                # Handle database lock errors
                if echo "$SITE_RESPONSE" | grep -q "database is locked"; then
                    (( RETRY_COUNT++ ))
                    echo "Database locked (attempt $RETRY_COUNT/$MAX_RETRIES). Retrying in $RETRY_DELAY seconds..."
                    sleep $RETRY_DELAY
                    RETRY_DELAY=$(( RETRY_DELAY * 2 ))
                    continue
                fi

                # Validate successful response
                SITE_ID=$(echo "$SITE_RESPONSE" | jq -r '.id')
                if [[ -n "$SITE_ID" && "$SITE_ID" != "null" ]]; then
                    # Install PHP extensions, non-interactively
                    apt-get install $APT_OPTS \
                        php8.3-cli php8.3-common php8.3-curl php8.3-dom php8.3-fileinfo \
                        php8.3-gd php8.3-iconv php8.3-intl php8.3-imagick php8.3-mbstring \
                        php8.3-mysql php8.3-pgsql php8.3-redis php8.3-sqlite3 php8.3-tidy \
                        php8.3-xml php8.3-xsl php8.3-zip php8.3-bcmath php8.3-ctype

                    echo "Site créé avec succès ! ID: $SITE_ID"
                    SITE_CREATED=true
                    break
                else
                    echo "Unexpected error creating site:" >&2
                    echo "$SITE_RESPONSE" | jq >&2
                    exit 1
                fi
            done

            if [[ "$SITE_CREATED" == true ]]; then
                exit 0
            else
                echo "Failed to create site after $MAX_RETRIES attempts" >&2
                exit 1
            fi
            ;;
        "error")
            echo "Server setup error" >&2
            echo "Status response: $STATUS_RESPONSE" >&2
            exit 1
            ;;
        *)
            echo "Status: $STATUS - Retry $i/$MAX_CHECKS in $CHECK_INTERVAL seconds..."
            sleep "$CHECK_INTERVAL"
            ;;
    esac
done

echo "Timeout waiting for server readiness" >&2
exit 1
