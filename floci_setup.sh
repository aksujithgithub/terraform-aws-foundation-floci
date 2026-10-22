brew install floci-io/floci/floci
floci start
eval "$(floci env)"

brew install awscli
aws --version
which aws
aws configure set aws_access_key_id test --profile floci
aws configure set aws_secret_access_key test --profile floci
aws configure set region eu-west-1 --profile floci
aws configure set output json --profile floci

[profile floci]
region = eu-west-1
output = json
endpoint_url = http://localhost:4566

aws sts get-caller-identity --endpoint-url http://localhost:4566