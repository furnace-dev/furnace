import fastapi
import uvicorn
from fastapi import Request, Response
from pprint import pprint


app = fastapi.FastAPI()
router = fastapi.APIRouter()


def hello():
    return "Hello Mojo🔥!"


# def register_callback(id: str, callback):
#     callbacks[id] = callback


async def tv_init(id: str, request: Request):
    print(f"id={id}")
    # body = await request.json()
    # print(body)
    body = (await request.body()).decode("utf-8")
    print(body)
    print(type(body))

    # 从请求中获取 JSON 数据
    # json_data = request.json()  # 使用同步方式获取 JSON 数据

    # 返回 text
    return Response("OK", media_type="text/plain")


async def tv_init1(request: Request):
    # /tv1/{id}
    # 从request取出{id}值
    id = request.path_params.get("id")
    print(f"id={id}")
    print(f"request.method={request.method}")
    # body = await request.json()
    # print(body)
    body = (await request.body()).decode("utf-8")
    print(body)
    print(type(body))

    # 从请求中获取 JSON 数据
    # json_data = request.json()  # 使用同步方式获取 JSON 数据

    # 返回 text
    return Response("OK", media_type="text/plain")


# 使用 add_api_route 添加新接口
router.add_api_route("/tv/{id}", endpoint=tv_init, methods=["POST"])
router.add_api_route("/tv1/{id}", endpoint=tv_init1, methods=["POST"])

# router.add_api_route("/", py_obj)
router.add_api_route("/", endpoint=hello, methods=["GET"])
app.include_router(router)

print("Start FastAPI WEB Server")
uvicorn.run(app, host="0.0.0.0", port=3000)
print("Done")
