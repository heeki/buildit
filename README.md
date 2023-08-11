## Build
In this environment, `makefile` is used for managing all the CLI commands.

1. Setup the local layer dependencies: `make layer`
2. Copy `environment.template` to `environment.sh` and setup your environment variables
3. Deploy the environment: `make sam`

## Testing (POST)
To test API Gateway locally: `make sam.local.api`

```
# local test: base validation
curl -s -XPOST -d @etc/payload.json http://127.0.0.1:3000/ | jq

# local test: missing payload
# note: local test doesn't seem to do request validation -> error code: 403 (from the function)
curl -s -XPOST http://127.0.0.1:3000/ -v

# deployed test: base validation
# note that the content-type header is required for request validation to work properly (curl and postman)
# note that without it curl defaulted to "content-type": "application/x-www-form-urlencoded"
export ENDPOINT=https://apiid.execute-api.us-east-1.amazonaws.com
curl -s -XPOST -d @etc/payload.json ${ENDPOINT}/dev/dice | jq
curl -s -XPOST -d @etc/payload.json -H 'content-type: application/json' ${ENDPOINT}/dev/dice | jq
curl -s -XPOST -d @etc/payload.json -H 'accept: application/json' ${ENDPOINT}/dev/dice | jq
curl -s -XPOST -d @etc/payload.json -H 'content-type: application/json' -H 'accept: application/json' ${ENDPOINT}/dev/dice | jq

# deployed test: missing payload
# note: api gateway will do request validation -> error code: 400 (from api gateway)
curl -s -XPOST ${ENDPOINT}/dev/dice | jq
```

## Testing (GET)
```
# local test: base validation
curl -s -XGET http://127.0.0.1:3000/?name=heeki | jq
curl -s -XGET ${ENDPOINT}/dev/?name=heeki | jq
```

## CodeWhisperer
Installed via VS Code Extensions, which took <5 minutes to complete the setup using the Builder Id, while also keeping the profile:default configuration for all other AWS Toolkit functionality.

## Troubleshooting
Due to a bug in boto3 with the built-in `python3.10` runtime, created a layer with a downrevved boto3 version and attached that to the function.
https://stackoverflow.com/questions/75887656/botocore-package-in-lambda-python-3-9-runtime-return-error-cannot-import-name
https://github.com/boto/boto3/issues/3648
```
START RequestId: 6b9044c9-f15f-4ad3-a9f0-843ed16438e9 Version: $LATEST
Traceback (most recent call last): Unable to import module 'fn': cannot import name 'DEPRECATED_SERVICE_NAMES' from 'botocore.docs' (/opt/python/botocore/docs/__init__.py)
END RequestId: 6b9044c9-f15f-4ad3-a9f0-843ed16438e9
```

Note that `name` is a reserved word with DDB, so needed to make the primary key `username` and then surface `name` in API responses.
