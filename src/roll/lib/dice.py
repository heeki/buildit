import datetime
import random
import uuid
from lib.ddb import AdptDynamoDB

class Dice:
    def __init__(self, session, table):
        self.session = session
        self.table = table
        self.ddb = AdptDynamoDB(session, table)

    def roll_dice(self, name):
        dice_roll = random.randint(1, 6)
        rid = str(uuid.uuid4())
        timestamp = datetime.datetime.now().isoformat()
        self.save_dice_roll(name, rid, timestamp, dice_roll)
        self.log_dice_roll(name, dice_roll)
        return dice_roll

    def save_dice_roll(self, name, rid, timestamp, roll):
        item = {
            "name": {"S": name},
            "rid": {"S": rid},
            "timestamp": {"S": timestamp},
            "diceRoll": {"N": str(roll)}
        }
        self.ddb.put(item)

    def log_dice_roll(self, name, roll):
        response = {
            "name": name,
            "diceRoll": roll
        }
        print(response)

    def get_dice_rolls(self, name=None):
        if name is not None:
            response = self.ddb.query(
                expression_values={":val": {"S": name}},
                expression_names={"#user": "name", "#ts": "timestamp"},
                key_condition="#user = :val",
                projection_expression="#user,rid,#ts,diceRoll",
            )
        else:
            response = []
        output = []
        for item in response:
            output.append({
                "name": item["name"]["S"],
                "rid": item["rid"]["S"],
                "timestamp": item["timestamp"]["S"],
                "diceRoll": item["diceRoll"]["N"]
            })
        return output