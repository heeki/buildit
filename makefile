include etc/environment.sh

layer:
	pip install -r requirements.txt --target=tmp/boto3/python --upgrade

lambda: lambda.package lambda.deploy
lambda.package:
	sam package -t ${LAMBDA_TEMPLATE} --output-template-file ${LAMBDA_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${LAMBDA_STACK}
lambda.deploy:
	sam deploy -t ${LAMBDA_OUTPUT} --stack-name ${LAMBDA_STACK} --parameter-overrides ${LAMBDA_PARAMS} --capabilities CAPABILITY_NAMED_IAM

lambda.local.api:
	sam local start-api -t ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json
lambda.local.api.build:
	sam build --profile ${PROFILE} --template ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --build-dir build --manifest requirements.txt --use-container
	sam local start-api -t build/template.yaml --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json
lambda.local.invoke:
	sam local invoke -t ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json -e etc/event.json Fn | jq

lambda.invoke.sync:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type RequestResponse --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "." > tmp/response.json
	cat tmp/response.json | jq -r ".LogResult" | base64 --decode
	cat tmp/fn.json | jq
lambda.invoke.async:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type Event --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "."
curl:
	curl -s -XPOST -d @etc/payload.json https://zet1a4pjd0.execute-api.us-east-1.amazonaws.com/dev/dice | jq

sam.logs:
	sam logs --stack-name ${LAMBDA_STACK} --tail
sam.logs.traces:
	sam logs --stack-name ${LAMBDA_STACK} --tail --include-traces

artillery:
	artillery run etc/artillery.yaml