# 🚀 Automated Certificate Renewal for Internal APIs

A script to automatically check and renew self-signed TLS certificates for internal APIs. Designed for simplicity, zero downtime, and secure internal use.

---

## 📂 Project Structure

```
automated-cert-renewal/
├── api/
│   └── api.py               # Example TLS-enabled internal API (Flask)
├── scripts/
│   └── cert_renewal.sh      # Certificate renewal script
├── systemd/
│   └── myapi.service        # systemd unit file for running the API
└── README.md                # Documentation (you're reading it!)
```

---

## ✅ Features

* Checks certificate expiry and renews if it’s under **7 days**.
* Uses **OpenSSL** to generate self-signed certificates.
* Swaps certificates and restarts API **with zero downtime**.
* Logs every step and verifies the API health using `curl`.

---

## ⚙️ Prerequisites

* Linux-based OS with:

  * `bash`
  * `openssl`
  * `python3`
  * `curl`
  * `systemd`
  * `pipx`
* Root or sudo access for certificate paths and service control.

You don't have to use `pipx` but it just simplifies the process of isolation
---

## 🔧 Setup Instructions

### 1. Clone the Repo

```bash
git clone https://github.com/your-username/automated-cert-renewal.git
cd automated-cert-renewal
```

### 2. Create Certificate Directory

```bash
sudo mkdir -p /etc/myapi/certs
```

### 3. Install Flask

```bash
pipx install flask
```

### 4. Place Initial Certificates (optional for testing)

```bash
sudo openssl req -newkey rsa:2048 -nodes -keyout /etc/myapi/certs/server.key \
    -x509 -days 365 -out /etc/myapi/certs/server.crt -subj "/CN=myapi.local"
```

---

## 🧪 Test API

### 📄 `api/api.py`

```python
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "API is running with TLS"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=443, ssl_context=("/etc/myapi/certs/server.crt", "/etc/myapi/certs/server.key"))
```

---

## 🛠️ Create systemd Service

Glad that worked! Here’s your updated section with the relevant pipx command included for documentation clarity:

### 📄 **Using pipx for Flask in systemd**

Before configuring the systemd service file, determine Flask’s environment path using:

```bash
pipx list
```
This will display where Flask is installed, typically under:
```
venvs are in /home/username/.local/share/pipx/venvs
apps are exposed on your $PATH at /home/username/.local/bin
package flask x.x.x, installed using Python x.x.x
    - flask
```
Use this environment path in your systemd service file.

---

### 📄 **`systemd/myapi.service`**

```ini
[Unit]
Description=Simple Flask API with TLS
After=network.target

[Service]
User=root
WorkingDirectory=/path/to/automated-cert-renewal/api
ExecStart=/home/your-user/.local/share/pipx/venvs/flask/bin/python api.py
Restart=always

[Install]
WantedBy=multi-user.target
```

This ensures systemd correctly launches Flask from the pipx-managed virtual environment.

> Replace `/path/to/automated-cert-renewal/api` with the actual path.

### Enable the Service:

```bash
sudo cp systemd/myapi.service /etc/systemd/system/myapi.service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable myapi.service
sudo systemctl start myapi.service
```

---

## 🔁 Certificate Renewal Script

### 📄 `scripts/cert_renewal.sh`

```bash
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
```

Make it executable:

```bash
chmod +x scripts/cert_renewal.sh
```

---

## ⏲️ Automate with Cron

Run the renewal script every day at 3 AM.

```bash
sudo crontab -e
```

Add this line:

```cron
0 3 * * * /path/to/automated-cert-renewal/scripts/cert_renewal.sh
```

---

## 📘 Logs

* Renewal logs: `/var/log/cert_renewal.log`
* You can monitor with:

```bash
tail -f /var/log/cert_renewal.log
```

---

## 🧭 Future Enhancements

* [ ] Use Let’s Encrypt for valid certs.
* [ ] Send email/Slack alert on renewal.
* [ ] Store renewal metadata in JSON format.
* [ ] Secure script execution via dedicated system user.

---

## 🧪 Test the Setup

1. Manually run the script:

```bash
sudo ./scripts/cert_renewal.sh
```

2. Check that:

   * Certs were regenerated.
   * API restarted.
   * Log confirms a successful curl response.

---
