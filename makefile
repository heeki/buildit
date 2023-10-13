include etc/environment.sh

# boto3
layer:
	pip install -r requirements.txt --target=tmp/boto3/python --upgrade

# lambda
lambda: lambda.package lambda.deploy
lambda.package:
	sam package -t ${LAMBDA_TEMPLATE} --output-template-file ${LAMBDA_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${LAMBDA_STACK}
lambda.deploy:
	sam deploy -t ${LAMBDA_OUTPUT} --stack-name ${LAMBDA_STACK} --parameter-overrides ${LAMBDA_PARAMS} --capabilities CAPABILITY_NAMED_IAM

# local testing
lambda.local.api:
	sam local start-api -t ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json
lambda.local.invoke:
	sam local invoke -t ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json -e etc/event.json Fn | jq
curl.local:
	curl -s -XPOST -d @etc/payload.json http://127.0.0.1:3000/dice | jq

# local testing with build
lambda.build:
	sam build --profile ${PROFILE} --template ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --build-dir build --manifest requirements.txt --use-container
lambda.local.api.build:
	sam local start-api -t build/template.yaml --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json

# testing deployed resources
lambda.invoke.sync:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type RequestResponse --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "." > tmp/response.json
	cat tmp/response.json | jq -r ".LogResult" | base64 --decode
	cat tmp/fn.json | jq
lambda.invoke.async:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type Event --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "."
curl:
	curl -s -XPOST -d @etc/payload.json ${O_API_ENDPOINT}/dice | jq

# cloudwatch logs
sam.logs:
	sam logs --stack-name ${LAMBDA_STACK} --tail
sam.logs.traces:
	sam logs --stack-name ${LAMBDA_STACK} --tail --include-traces

# load testing
artillery:
	artillery run etc/artillery.yaml

# infrastructure for ecs application
infrastructure: infrastructure.package infrastructure.deploy
infrastructure.package:
	sam package --profile ${PROFILE} -t ${INFRASTRUCTURE_TEMPLATE} --output-template-file ${INFRASTRUCTURE_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${INFRASTRUCTURE_STACK}
infrastructure.deploy:
	sam deploy --profile ${PROFILE} -t ${INFRASTRUCTURE_OUTPUT} --stack-name ${INFRASTRUCTURE_STACK} --parameter-overrides ${INFRASTRUCTURE_PARAMS} --capabilities CAPABILITY_NAMED_IAM

# ecs cluster and service
ecs: ecs.package ecs.deploy
ecs.package:
	sam package --profile ${PROFILE} -t ${ECS_TEMPLATE} --output-template-file ${ECS_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${ECS_STACK}
ecs.deploy:
	sam deploy --profile ${PROFILE} -t ${ECS_OUTPUT} --stack-name ${ECS_STACK} --parameter-overrides ${ECS_PARAMS} --capabilities CAPABILITY_NAMED_IAM
