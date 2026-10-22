brew install floci-io/floci/floci

floci start
eval "$(floci env)"

aws sts get-caller-identity --endpoint-url http://localhost:4566