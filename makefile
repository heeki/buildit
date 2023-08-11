include etc/environment.sh

layer:
	pip install -r requirements.txt --target=tmp/boto3/python --upgrade

sam: sam.package sam.deploy
sam.package:
	sam package -t ${SAM_TEMPLATE} --output-template-file ${SAM_OUTPUT} --s3-bucket ${S3BUCKET} --s3-prefix ${SAM_STACK}
sam.deploy:
	sam deploy -t ${SAM_OUTPUT} --stack-name ${SAM_STACK} --parameter-overrides ${SAM_PARAMS} --capabilities CAPABILITY_NAMED_IAM

sam.local.api:
	sam local start-api -t ${SAM_TEMPLATE} --parameter-overrides ${SAM_PARAMS} --env-vars etc/envvars.json
sam.local.api.build:
	sam build --profile ${PROFILE} --template ${SAM_TEMPLATE} --parameter-overrides ${SAM_PARAMS} --build-dir build --manifest requirements.txt --use-container
	sam local start-api -t build/template.yaml --parameter-overrides ${SAM_PARAMS} --env-vars etc/envvars.json
sam.local.invoke:
	sam local invoke -t ${SAM_TEMPLATE} --parameter-overrides ${SAM_PARAMS} --env-vars etc/envvars.json -e etc/event.json Fn | jq
sam.invoke.sync:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type RequestResponse --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "." > tmp/response.json
	cat tmp/response.json | jq -r ".LogResult" | base64 --decode
	cat tmp/fn.json | jq
sam.invoke.async:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type Event --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "."

artillery:
	artillery run etc/artillery.yaml