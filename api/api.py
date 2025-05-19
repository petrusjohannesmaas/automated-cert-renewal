from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "API is running with TLS"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=443, ssl_context=("/etc/myapi/certs/server.crt", "/etc/myapi/certs/server.key"))