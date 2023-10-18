include etc/environment.sh

# boto3
layer:
	pip install -r src/layer/requirements.txt --target=tmp/boto3/python --upgrade

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
curl.local.get:
	curl -s -XGET http://127.0.0.1:3000/dice\?name\=test | jq -c '.[]'
curl.local.post:
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
curl.apigw.get:
	curl -s -XGET ${O_API_ENDPOINT}/dice\?name\=test | jq -c '.[]'
curl.apigw.post:
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

# fastapi testing
fastapi:
	cd src/application && uvicorn fapi:server --reload
curl.fastapi.get:
	curl -s -XGET http://127.0.0.1:8000/dice/\?name\=test | jq -c '.[]'
curl.fastapi.post:
	curl -s -XPOST -H "content-type: application/json" -d @etc/payload.json http://127.0.0.1:8000/dice/ | jq

# containerize spring application
docker: docker.build docker.login docker.tag docker.push
docker.build:
	docker build -f dockerfile -t ${C_TAG} .
docker.login:
	aws ecr --profile ${PROFILE} get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${C_REPO_BASE}
docker.tag:
	docker tag ${C_TAG} ${C_REPO_URI}
docker.push:
	docker push ${C_REPO_URI}
docker.run:
	# -p hostport:containerport
	docker run -p 8080:8080 --env-file etc/environment.docker ${C_TAG}

# docker testing
curl.docker.get:
	curl -s -XGET http://127.0.0.1:8080/dice/\?name\=test | jq -c '.[]'
curl.docker.post:
	curl -s -XPOST -H "content-type: application/json" -d @etc/payload.json http://127.0.0.1:8080/dice/ | jq

# ecs cluster and service
ecs: ecs.package ecs.deploy
ecs.package:
	sam package --profile ${PROFILE} -t ${ECS_TEMPLATE} --output-template-file ${ECS_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${ECS_STACK}
ecs.deploy:
	sam deploy --profile ${PROFILE} -t ${ECS_OUTPUT} --stack-name ${ECS_STACK} --parameter-overrides ${ECS_PARAMS} --capabilities CAPABILITY_NAMED_IAM

# ecs testing
curl.ecs.get:
	curl -s -XGET https://buildit.heeki.cloud/dice/\?name\=test | jq -c '.[]'
curl.ecs.post:
	curl -s -XPOST -H "content-type: application/json" -d @etc/payload.json https://buildit.heeki.cloud/dice/ | jq