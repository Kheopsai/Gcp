#!/bin/bash
sudo su
mkdir -p /root/.ssh && touch /root/.ssh/authorized_keys && echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmiFxUhuikeF/o957k6Z4yua8sf4vmZtofrt2vGikg3ob86Tt+cQcsej0PHLMKzYXNyb+2v41UYEzHPXHwucOx8ywxSN9Lfzya7fz2LYc61FcSrjxfURWHg3BlZp+dK6wchg7YqvM1pFkqkBV99Y0z5RAul5fngip9sT6fH3RDm8enetMjAC8JN7kamqiMwUE2C0FUblaEIsfFnGKiEv3YmRdBuSxPFc2upTAd1D14cCFPoCT2d1G7CwmI2LhDYs+ESpCnn+gI2VVvQRvA6UaHAwi4aRu+sQUHmfTCsK0nqe5G77Bqu4Nc0QXCLMmX7du2gS/Vy6MjzHauZ8mtHUin' >> /root/.ssh/authorized_keys

# Set Permissions
chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys

# Récupérer les métadonnées de la VM GCP
IP=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google")
PORT=22
NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
OS="ubuntu_22"
WEBSERVER="nginx"
PHP_VERSION="8.2"
DATABASE="none"

# Envoyer la requête CURL avec les valeurs dynamiques
curl --request POST \
    "https://kheops.cloud/api/projects/4/servers" \
    --header "Authorization: Bearer $AUTH_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --data "{
    \"provider\": \"custom\",
    \"server_provider\": \"custom\",
    \"ip\": \"$IP\",
    \"port\": \"$PORT\",
    \"name\": \"$NAME\",
    \"os\": \"$OS\",
    \"webserver\": \"$WEBSERVER\",
    \"database\": \"$DATABASE\",
    \"php\": \"$PHP_VERSION\"
}"