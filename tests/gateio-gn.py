# https://github.com/limo010/-/blob/main/gate_%E5%A4%9A%E7%A9%BA%E8%B6%8B%E5%8A%BF%E7%BA%BF/requirement_GN.py
import time
import hashlib
import hmac
import requests
import json
# from send_email import save_data
import threading
# json_name = "gate_日志.json"
# try:
#     with open('set.json', encoding="utf-8") as file_obj:
#         data_temp = json.load(file_obj)
#     file_obj.close()
# except Exception as e:
#     print(e)
# "http": "http://127.0.0.1:33210",
# "https": "http://127.0.0.1:33210"
proxies = {
#"http": "http://127.0.0.1:33210",
#"https": "http://127.0.0.1:33210"
}
# export https_proxy=http://127.0.0.1:33210 http_proxy=http://127.0.0.1:33210 all_proxy=socks5://127.0.0.1:33211

def gen_sign(method, url, query_string=None, payload_string=None):
    key = data_temp['key']        # api_key
    secret = data_temp['secret'] # api_secret

    t = time.time()
    m = hashlib.sha512()
    m.update((payload_string or "").encode('utf-8'))
    hashed_payload = m.hexdigest()
    s = '%s\n%s\n%s\n%s\n%s' % (method, url, query_string or "", hashed_payload, t)
    sign = hmac.new(secret.encode('utf-8'), s.encode('utf-8'), hashlib.sha512).hexdigest()
    return {'KEY': key, 'Timestamp': str(t), 'SIGN': sign}

def orders(size, close, symbol, tif, price):
    host = "https://api.gateio.ws"
    prefix = "/api/v4"
    headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}
    url = '/futures/usdt/orders'
    query_param = ''
    # 数量正数为开多，负数为开空，0为平仓;close = 1 平仓,
    auto_size = ""
    reduce_only = ""
    temp = {}
    if close == 0:
        temp['open'] = '开多'
    elif close == 1:
        temp['open'] = '一键平多仓'
    else:
        temp['open'] = '减多仓'

    # 平仓
    if close == 1:
        if size < 0:
            auto_size = "close_long"
        else:
            auto_size = "close_short"
        size = 0
        close = False
        reduce_only = True
    # 减仓
    if close == 2:
        reduce_only = True
    body = {"contract":symbol,"size":size,"price": price,"tif": tif,"close": close,"auto_size":auto_size,"reduce_only":reduce_only}
    body = json.dumps(body)
    # print(body)
    # `gen_sign` 的实现参考认证一章
    sign_headers = gen_sign('POST', prefix + url, query_param, body)
    headers.update(sign_headers)
    try:
        ts1 = time.time()
        r = requests.request('POST', host + prefix + url, headers=headers, data=body, timeout=10, proxies = proxies)
        ts2 = time.time()
        temp['time'] = time.strftime('%Y-%m-%d %H:%M:%S')
        # print(r.json())
        if size > 0:
            temp['gate'] = "开多"
        else:
            temp['gate'] = '开空'
        temp['延迟'] = ts2 - ts1
        temp['response'] = r.json()
        t1 = threading.Thread(target=save_data, args=(temp, json_name))
        t1.start()
    except Exception as e:
        print(e)


# 检查仓位代码
def cangweichaxun(symbol):
    host = "https://api.gateio.ws"
    prefix = "/api/v4"
    headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}
    url = '/futures/usdt/positions/{}'.format(symbol)
    query_param = ''
    # `gen_sign` 的实现参考认证一章
    sign_headers = gen_sign('GET', prefix + url, query_param)
    headers.update(sign_headers)
    r = requests.request('GET', host + prefix + url, headers=headers, timeout=10, proxies=proxies)
    # print(r.json())
    return r.json()

def get_gate_acount():
    host = "https://api.gateio.ws"
    prefix = "/api/v4"
    headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}

    url = '/futures/usdt/accounts'
    query_param = ''
    # `gen_sign` 的实现参考认证一章
    sign_headers = gen_sign('GET', prefix + url, query_param)
    headers.update(sign_headers)
    r = requests.request('GET', host + prefix + url, headers=headers)
    # print(r.json())
    return float(r.json()['available'])

def get_gate_hold():
    host = "https://api.gateio.ws"
    prefix = "/api/v4"
    headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}

    url = '/futures/usdt/positions/BTC_USDT'
    query_param = ''
    # `gen_sign` 的实现参考认证一章
    sign_headers = gen_sign('GET', prefix + url, query_param)
    headers.update(sign_headers)
    r = requests.request('GET', host + prefix + url, headers=headers)
    # print(r.json())
    return (r.json()['size'])

# 条件单
def condition_order(rule, order_type):
    host = "https://api.gateio.ws"
    prefix = "/api/v4"
    headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}

    url = '/futures/usdt/price_orders'
    query_param = ''
    # rule = 1 止盈 rule = 2 止损
    body = {"initial":{"contract":"BTC_USDT","size":0,"price":"0", "tif": "ioc", "reduce_only": True, "auto_size": "close_short"},"trigger":{"strategy_type":0,"price_type":0,"price":"30000","rule":rule,"expiration":86400},"order_type": order_type}
    body = json.dumps(body)
    # `gen_sign` 的实现参考认证一章
    sign_headers = gen_sign('POST', prefix + url, query_param, body)
    headers.update(sign_headers)
    ts1 = time.time()
    r = requests.request('POST', host + prefix + url, headers=headers, data=body)
    ts2 = time.time()
    temp = {}
    temp['open'] = "止盈止损单"
    temp['time'] = time.strftime('%Y-%m-%d %H:%M:%S')
    temp['延迟'] = ts2 - ts1
    temp['response'] = r.json()
    t1 = threading.Thread(target=save_data, args=(temp, json_name))
    t1.start()
    print(r.json())

if __name__ == '__main__':
    # print(get_gate_hold())
    ts1 = time.time()
    # orders(-1,1,'BTC_USDT',"poc", "30500")
    # rule=1止盈，2止损
    rule = 1; order_type = "close-short-position"
    # condition_order(rule, order_type)
    # close为1 即为平仓
    # 开多10张  10 0 'BTCUSDT' 'IOC' '0'
    # 一键平多仓 -1 1 'BTCUSDT' 'IOC' '0'
    # 减多仓 -1 2 'BTCUSDT' 'IOC' '0'
    # 开多 10张
    # print(orders(10, 0, 'BTC_USDT', 'ioc', '0'))
    # 开空 10张
    # print(orders(-10, 0, 'BTC_USDT', 'ioc', '0'))
    # 一键平多仓
    # print(orders(-1, 1, 'BTC_USDT', 'ioc', '0'))
    # 一键平空仓
    # print(orders(1, 1, 'BTC_USDT', 'ioc', '0'))

    ts2 = time.time()

    # 获取仓位
    print(cangweichaxun("BCH_USDT"))

    print("延迟",ts2-ts1)