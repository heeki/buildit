import json
from lib.app import App
from aws_xray_sdk.core import patch_all
from aws_xray_sdk.core import xray_recorder

# initialization
patch_all()
app = App()

# lambda helpers
def get_name(event):
    body = event.get("body")
    qsp = event.get("queryStringParameters")
    name = None
    if body is not None:
        body = json.loads(event["body"])
        name = body.get("name")
    elif qsp is not None:
        name = qsp.get("name")
    return name

def build_response(code, body):
    response = {
        "isBase64Encoded": False,
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }
    return response

# lambda handler
def handler(event, context):
    if app.is_failure():
        output = build_response(503, json.dumps({
            "reason": "service unavailable"
        }))
    else:
        print(app)
        print(json.dumps(event))

        # input extraction
        name = get_name(event)

        # input validation
        if name is None:
            output = build_response(403, {
                "reason": "name required in post body (name must be between 2 and 30 characters)"
            })
        elif not app.is_valid_name(name):
            output = build_response(403, {
                "name": name,
                "reason": "invalid name length (name must be between 2 and 30 characters)"
            })

        # method handlers
        elif event.get("httpMethod") == "GET":
            code, response = app.do_get(name)
            output = build_response(code, response)
        elif event.get("httpMethod") == "POST":
            code, response = app.do_post(name)
            output = build_response(code, response)
        else:
            output = build_response(403, {
                "reason": "invalid method"
            })

    print(json.dumps(output))
    return output
