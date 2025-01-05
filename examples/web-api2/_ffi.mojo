fn ffi_code() -> StringLiteral:
    return """from fastapi import Request, Response
from ctypes import CFUNCTYPE, c_int, create_string_buffer


_tv_init = None


def set_tv_init(tv_init):
    global _tv_init
    _tv_init = tv_init


async def hello():
    return 'OK'


async def tv_init(request: Request):
    # /tv1/{id}
    # 从request取出{id}值
    id = request.path_params.get("id")
    # print(f"id={id}")
    # print(f'request.method={request.method}')
    # body = await request.json()
    # print(body)
    body_c_ptr = await request.body()
    # body = body_c_ptr.decode("utf-8")
    # print(body)
    # print(type(body))

    # 转换为 char*
    # body_c_ptr = body.encode("utf-8")

    # # 开辟char*缓冲区，作为字符串返回值
    # result_buff_size = 1024  # 假设最大返回字符串长度为1024
    # Allocate a buffer for storing the return value, assuming a maximum of 10 characters

    # Convert id to bytes
    id_c_ptr = id.encode('utf-8')

    result_buff_size = 64
    result_buff = create_string_buffer(result_buff_size)

    # 调用_tv_init函数，传入缓冲区和其大小
    # p = 10
    returned_size = _tv_init(id_c_ptr, body_c_ptr, result_buff, result_buff_size)

    # print(f"res={res}")

    # 将返回的char*转换为Python字符串
    result_str = result_buff.value[:returned_size].decode("utf-8")

    # 返回 text
    return Response(result_str, media_type="text/plain")
"""