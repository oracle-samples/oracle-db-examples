#!/usr/bin/env python3
"""Read random customers through CustomerController."""

import argparse
import time

import requests

from stress_test_common import BASE_URL


def main() -> None:
    parser = argparse.ArgumentParser(description="Read random customers through /customers/random")
    parser.add_argument("-n", "--count", type=int, default=100, help="Number of random reads")
    args = parser.parse_args()

    session = requests.Session()
    url = f"{BASE_URL}/customers/random"
    latencies = []

    print(f"Fetching {args.count} random customers from {url}")
    for i in range(args.count):
        start = time.perf_counter()
        resp = session.get(url, timeout=10)
        resp.raise_for_status()
        latencies.append(time.perf_counter() - start)
        print(f"{i + 1:03d}: {resp.status_code} | {resp.text.strip()}")

    avg_ms = sum(latencies) / len(latencies) * 1000 if latencies else 0.0
    print(f"Done. Avg latency: {avg_ms:.1f} ms")


if __name__ == "__main__":
    main()