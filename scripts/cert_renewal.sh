#!/bin/bash

CERT_DIR="/etc/myapi/certs"
CERT_FILE="$CERT_DIR/server.crt"
KEY_FILE="$CERT_DIR/server.key"
EXPIRY_THRESHOLD=604800  # 7 days
LOG_FILE="/var/log/cert_renewal.log"

check_expiry() {
    if openssl x509 -checkend $EXPIRY_THRESHOLD -noout -in "$CERT_FILE"; then
        echo "$(date): Certificate is still valid." | tee -a "$LOG_FILE"
        exit 0
    else
        echo "$(date): Certificate needs renewal!" | tee -a "$LOG_FILE"
        renew_certificate
    fi
}

renew_certificate() {
    echo "$(date): Generating new self-signed certificate..." | tee -a "$LOG_FILE"
    openssl req -newkey rsa:2048 -nodes -keyout "$KEY_FILE" -x509 -days 365 -out "$CERT_FILE" -subj "/CN=myapi.local"
    
    echo "$(date): Certificate renewed successfully!" | tee -a "$LOG_FILE"

    systemctl restart myapi.service

    sleep 2
    RESPONSE=$(curl -sk https://localhost/)
    if [[ "$RESPONSE" == *"API is running with TLS"* ]]; then
        echo "$(date): API is running successfully with the new certificate." | tee -a "$LOG_FILE"
    else
        echo "$(date): API health check failed after certificate renewal!" | tee -a "$LOG_FILE"
    fi
}

check_expiry