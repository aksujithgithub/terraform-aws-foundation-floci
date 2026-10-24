#!/usr/bin/env bash
set -euo pipefail

# Install dependencies
dnf update -y
dnf install -y python3 python3-pip git jq awscli

# Create app user and directory
useradd -r -s /sbin/nologin appuser || true
mkdir -p /opt/app
cd /opt/app

# Fetch DB credentials from Secrets Manager at boot
# Retries are needed since the instance may start before IAM propagates
SECRET_NAME="${db_secret_name}"
REGION="${aws_region}"
ENDPOINT_ARGS=""
%{ if localstack_endpoint != "" ~}
ENDPOINT_ARGS="--endpoint-url ${localstack_endpoint}"
%{ endif ~}

for i in 1 2 3 4 5; do
  SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    $ENDPOINT_ARGS \
    --query SecretString \
    --output text 2>/dev/null) && break
  echo "Attempt $i failed, retrying in 10s..."
  sleep 10
done

# Write env file from the JSON secret
cat > /opt/app/.env <<EOF
DB_HOST=$(echo "$SECRET_JSON" | jq -r '.db_host')
DB_PORT=$(echo "$SECRET_JSON" | jq -r '.db_port')
DB_NAME=$(echo "$SECRET_JSON" | jq -r '.db_name')
DB_USER=$(echo "$SECRET_JSON" | jq -r '.db_username')
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.db_password')
SECRET_NAME=$SECRET_NAME
AWS_DEFAULT_REGION=$REGION
%{ if localstack_endpoint != "" ~}
AWS_ENDPOINT_URL=${localstack_endpoint}
%{ endif ~}
EOF

chmod 600 /opt/app/.env

# Install Python packages
pip3 install flask flask-sqlalchemy pymysql cryptography python-dotenv boto3

# Write the Flask app
cat > /opt/app/app.py <<'PYEOF'
"""
Flask CRUD app — fetches DB credentials from Secrets Manager at startup.
"""
import json
import os

import boto3
from botocore.config import Config
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy

load_dotenv("/opt/app/.env")


def get_secret() -> dict:
    secret_name = os.environ["SECRET_NAME"]
    region = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
    endpoint = os.environ.get("AWS_ENDPOINT_URL")

    kwargs = dict(region_name=region, config=Config(retries={"max_attempts": 3}))
    if endpoint:
        kwargs["endpoint_url"] = endpoint

    client = boto3.client("secretsmanager", **kwargs)
    resp = client.get_secret_value(SecretId=secret_name)
    return json.loads(resp["SecretString"])


secret = get_secret()

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = (
    "mysql+pymysql://{db_username}:{db_password}@{db_host}:{db_port}/{db_name}".format(
        **secret
    )
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)


class Item(db.Model):
    __tablename__ = "items"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)
    description = db.Column(db.Text, nullable=True)

    def to_dict(self):
        return {"id": self.id, "name": self.name, "description": self.description}


with app.app_context():
    db.create_all()


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/items", methods=["GET"])
def list_items():
    return jsonify([i.to_dict() for i in Item.query.all()]), 200


@app.route("/items", methods=["POST"])
def create_item():
    data = request.get_json()
    if not data or "name" not in data:
        return jsonify({"error": "name is required"}), 400
    item = Item(name=data["name"], description=data.get("description"))
    db.session.add(item)
    db.session.commit()
    return jsonify(item.to_dict()), 201


@app.route("/items/<int:item_id>", methods=["GET"])
def get_item(item_id):
    return jsonify(db.get_or_404(Item, item_id).to_dict()), 200


@app.route("/items/<int:item_id>", methods=["PUT"])
def update_item(item_id):
    item = db.get_or_404(Item, item_id)
    data = request.get_json()
    if "name" in data:
        item.name = data["name"]
    if "description" in data:
        item.description = data["description"]
    db.session.commit()
    return jsonify(item.to_dict()), 200


@app.route("/items/<int:item_id>", methods=["DELETE"])
def delete_item(item_id):
    item = db.get_or_404(Item, item_id)
    db.session.delete(item)
    db.session.commit()
    return jsonify({"message": "deleted"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PYEOF

chown -R appuser:appuser /opt/app

# Systemd service
cat > /etc/systemd/system/flaskapp.service <<EOF
[Unit]
Description=Flask CRUD App
After=network.target

[Service]
User=appuser
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=5
EnvironmentFile=/opt/app/.env

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flaskapp
systemctl start flaskapp
