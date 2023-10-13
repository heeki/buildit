import boto3
import json
import os
import random
from aws_xray_sdk.core import patch_all
from aws_xray_sdk.core import xray_recorder
from lib.dice import Dice

# initialization
session = boto3.session.Session()
patch_all()
dice_table = os.environ.get("DICE_TABLE")
chance_of_failure = os.environ.get("CHANCE_OF_FAILURE")
d = Dice(session, dice_table)

# helper functions
def build_response(code, body):
    headers = {
        "Content-Type": "application/json"
    }
    response = {
        "isBase64Encoded": False,
        "statusCode": code,
        "headers": headers,
        "body": body
    }
    return response

def is_valid_name(name):
    response = False
    if len(name) > 2 and len(name) <= 30:
        response = True
    return response

def do_dice_roll(event):
    response_code = 403
    response = {
        "reason": "name required in post body (name must be between 2 and 30 characters)"
    }
    if "body" in event and event["body"] is not None:
        body = json.loads(event["body"])
        if "name" in body:
            name = body["name"]
            if is_valid_name(name):
                response_code = 200
                dice_roll = d.roll_dice(name)
                response = {
                    "diceRoll": dice_roll
                }
            else:
                response = {
                    "name": name,
                    "reason": "invalid name length (name must be between 2 and 30 characters)"
                }
    return response_code, response

def get_dice_rolls(event):
    name = None
    qsp = event["queryStringParameters"]
    if "name" in qsp:   
        name = qsp["name"]
    response_code = 200
    response = d.get_dice_rolls(name)
    return response_code, response

def handler(event, context):
    print(json.dumps(event))
    if event["httpMethod"] == "POST":
        if random.randint(1, 100) <= int(chance_of_failure):
            response_code = 503
            response = {
                "reason": "service unavailable"
            }
        else:
            response_code, response = do_dice_roll(event)
    else:
        response_code, response = get_dice_rolls(event)
    output = build_response(response_code, json.dumps(response))
    print(json.dumps(output))
    return output
