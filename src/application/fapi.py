import json
from lib.app import App
from fastapi import FastAPI, Query
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Annotated

# initialization
app = App()
server = FastAPI()

# fastapi helpers
class Roll(BaseModel):
    name: str = Field(min_length=2, max_length=30)

# fastapi handlers
@server.get("/")
async def root():
    output = {"message": "hello world"}
    return output

# method handlers
@server.get("/dice/")
async def dice(name: Annotated[str, Query(min_length=2, max_length=30)]):
    print(app)
    code, response = app.do_get(name)
    output = JSONResponse(status_code=code,
        content=response
    )
    return output

@server.post("/dice/")
async def dice(roll: Roll):
    if app.is_failure():
        output = JSONResponse(status_code=503,
            content="service unavailable"
        )
    else:
        print(app)
        print(roll.model_dump_json())
        code, response = app.do_post(roll.name)
        output = JSONResponse(status_code=code,
            content=response
        )
    return output

@server.exception_handler(RequestValidationError)
async def request_validation_handler(request, e):
    return JSONResponse(status_code=403,
        content=jsonable_encoder(e)
    )