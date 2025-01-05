from blacksheep import Application, get, post, Request, Response, Content
from urllib.parse import urlparse, urlunparse
from datetime import datetime

app = Application()


@get("/")
async def home():
    return f"OK! {datetime.now().isoformat()}"


@post("/tv/{id}")
async def tv_init(request: Request):
    id = request.route_values["id"]
    data = await request.json()
    # data = await request.json()
    # data = ''
    return 'ok'


@post("/order/{id}")
async def order_init(request: Request):
    id = request.route_values["id"]
    # return f"Order initialized with ID: {id}"
    return "ok"
