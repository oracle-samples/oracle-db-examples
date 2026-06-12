#!/usr/bin/env python3
"""Create many customers through CustomerController."""

import argparse
from pathlib import Path

import requests

from stress_test_common import BASE_URL, COUNTRIES, random_customer, save_json_lines


def main() -> None:
    parser = argparse.ArgumentParser(description="Create customers through /customer.")
    parser.add_argument("-n", "--count", type=int, default=1000, help="Number of customers to create")
    parser.add_argument("-o", "--output", default="generated_customers.jsonl", help="Where to store created customer payloads")
    args = parser.parse_args()

    session = requests.Session()
    url = f"{BASE_URL}/customers"
    created = []

    print(f"Creating {args.count} customers at {url}")
    for i in range(args.count):
        payload = random_customer(country=COUNTRIES[i % len(COUNTRIES)])
        resp = session.post(url, json=payload, timeout=10)
        resp.raise_for_status()
        created.append(payload)
        if (i + 1) % 100 == 0 or i == args.count - 1:
            print(f"Created {i + 1}/{args.count}")

    save_json_lines(args.output, created)
    print(f"Saved created customer payloads to {Path(args.output).resolve()}")


if __name__ == "__main__":
    main()