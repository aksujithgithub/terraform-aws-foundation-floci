# Start MySQL locally (or use Docker)
docker run -d --name mysql-local \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=appdb \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=password \
  -p 3306:3306 mysql:8.0

# Store a test secret in LocalStack
aws secretsmanager create-secret \
  --name "terraform-aws-foundation/local/db" \
  --secret-string '{"db_host":"localhost","db_port":"3306","db_name":"appdb","db_username":"admin","db_password":"password"}' \
  --profile floci

# Run the Flask app
cd app
cp .env.example .env
pip3 install -r requirements.txt
SECRET_NAME="terraform-aws-foundation/local/db" \
AWS_DEFAULT_REGION=us-east-1 \
AWS_ENDPOINT_URL=http://localhost:4566 \
python3 app.py
