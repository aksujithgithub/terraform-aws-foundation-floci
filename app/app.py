"""
Flask CRUD application.
DB credentials are fetched from AWS Secrets Manager at startup.
No credentials are stored in environment files or config — only the secret name.
"""

import json
import os

import boto3
from botocore.config import Config
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy

load_dotenv()


def get_db_credentials() -> dict:
    """Fetch DB credentials from Secrets Manager.

    Supports both real AWS and LocalStack (via AWS_ENDPOINT_URL env var).
    """
    secret_name = os.environ["SECRET_NAME"]
    region = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
    endpoint = os.environ.get("AWS_ENDPOINT_URL")  # set for LocalStack only

    kwargs: dict = {
        "region_name": region,
        "config": Config(retries={"max_attempts": 3, "mode": "standard"}),
    }
    if endpoint:
        kwargs["endpoint_url"] = endpoint

    client = boto3.client("secretsmanager", **kwargs)
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])


# Fetch credentials once at startup
_creds = get_db_credentials()

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = (
    "mysql+pymysql://{db_username}:{db_password}@{db_host}:{db_port}/{db_name}".format(
        **_creds
    )
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)


class Item(db.Model):
    """Item stored in the CRUD database."""

    __tablename__ = "items"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)
    description = db.Column(db.Text, nullable=True)

    def to_dict(self) -> dict:
        return {"id": self.id, "name": self.name, "description": self.description}


with app.app_context():
    db.create_all()


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


# ---------------------------------------------------------------------------
# CRUD endpoints
# ---------------------------------------------------------------------------


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
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port)
