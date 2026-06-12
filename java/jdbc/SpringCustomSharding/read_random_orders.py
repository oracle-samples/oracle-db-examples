#!/usr/bin/env python3
"""Read random orders through OrderController."""

import argparse
import random
import time

import requests

from stress_test_common import BASE_URL, load_json_lines


def main() -> None:
    parser = argparse.ArgumentParser(description="Read random orders through /orders/{country}/{custId}/{orderId}.")
    parser.add_argument("-n", "--count", type=int, default=100, help="Number of random order reads")
    parser.add_argument("-i", "--input", default="generated_orders.jsonl", help="JSONL file created by create_orders.py")
    args = parser.parse_args()

    order_ids = load_json_lines(args.input)
    if not order_ids:
        raise SystemExit(f"No order ids found in {args.input}. Run create_orders.py first.")

    session = requests.Session()
    latencies = []

    print(f"Reading {args.count} random orders using ids from {args.input}")
    for i in range(args.count):
        order_id = random.choice(order_ids)
        url = f"{BASE_URL}/orders/{order_id['country']}/{order_id['custId']}/{order_id['orderId']}"
        start = time.perf_counter()
        resp = session.get(url, timeout=10)
        resp.raise_for_status()
        latencies.append(time.perf_counter() - start)
        print(f"{i + 1:03d}: {resp.status_code} | {order_id['country']}/{order_id['custId']}/{order_id['orderId']}")

    avg_ms = sum(latencies) / len(latencies) * 1000 if latencies else 0.0
    print(f"Done. Avg latency: {avg_ms:.1f} ms")


if __name__ == "__main__":
    main()