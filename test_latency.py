import asyncio
import time

from util.public_api import get_private_api
from util.util import get_order_book_mid
from utils.stream_logger import logger

# This example measures the round-trip time when placing orders with an exchange


def calculate_percentiles(data, percentiles):
    data_sorted = sorted(data)
    results = {}
    for p in percentiles:
        k = (len(data_sorted) - 1) * (p / 100)
        f = Int(k)  # Floor index
        c = f + 1  # Ceiling index
        if c >= len(data_sorted):
            results[p] = data_sorted[f]
        else:
            d0 = data_sorted[f] * (c - k)
            d1 = data_sorted[c] * (k - f)
            results[p] = d0 + d1
    return results


async def main():
    exchange_name = "gateioswapu"
    user_name = "zsyhsapi"
    symbol = 'XRP/USDT'
    exchange_user = "{}_{}".format(exchange_name, user_name)
    api = await get_private_api(logger, exchange_user, symbol=None, get_keys_from_file=True)
    await api.load_markets()
    # api.verbose = True

    market = api.market(symbol)
    mid_price = get_order_book_mid(await api.fetch_order_book(symbol))

    # we will place limit buy order at 3/4 of the price to make sure they're not triggered

    price = mid_price * 0.8
    amount = max(round(api.get_min_cost(symbol) / price, 8), api.get_min_amount(symbol)) + api.amount_tick_size(symbol)

    results = []

    for i in range(0, 600):
        try:
            order = await api.create_order(symbol, 'limit', 'buy', amount, price)
            started = api.microseconds() / 1000
            await api.cancel_order(order['id'], symbol)
            ended = api.microseconds() / 1000
            elapsed = ended - started

            if i > 0:  # Exclude the first request
                results.append(elapsed)

            logger.info(order)
            logger.info(results)
        except Exception as e:
            logger.error(e)
            logger.info(await api.cancel_all_orders(symbol))
        finally:
            await asyncio.sleep(10)

    if results:
        percentiles = calculate_percentiles(results, [1, 15, 95])
        rtt = round(sum(results) / len(results), 4)
        min_time = min(results)
        max_time = max(results)

        logger.info('Successfully tested {} orders.\n'
                    'Average round-trip time: {} ms\n'
                    'Min time: {} ms\n'
                    'Max time: {} ms\n'
                    '1st percentile: {} ms\n'
                    '15th percentile: {} ms\n'
                    '95th percentile: {} ms'.format(
                        len(results), rtt, min_time, max_time, percentiles[1], percentiles[15], percentiles[95]))
    else:
        logger.info('No valid round-trip times recorded.')

    logger.info(await api.cancel_all_orders(symbol))


asyncio.get_event_loop().run_until_complete(main())
