import boto3
import json
import os
import random
from lib.dice import Dice

class App:
    def __init__(self):
        self.session = boto3.session.Session()
        self.dice_table = os.environ.get("DICE_TABLE")
        self.chance_of_failure = os.environ.get("CHANCE_OF_FAILURE")
        self.d = Dice(self.session, self.dice_table)

    def __str__(self):
        return json.dumps({
            "dice_table": self.dice_table,
            "chance_of_failure": self.chance_of_failure
        })

    def is_valid_name(self, name):
        response = False
        if len(name) > 2 and len(name) <= 30:
            response = True
        return response

    def is_failure(self):
        return random.randint(1, 100) <= int(self.chance_of_failure)

    def do_get(self, name):
        code = 200
        response = self.d.get_dice_rolls(name)
        return code, response

    def do_post(self, name):
        code = 200
        response = {
            "diceRoll": self.d.roll_dice(name)
        }
        return code, response
