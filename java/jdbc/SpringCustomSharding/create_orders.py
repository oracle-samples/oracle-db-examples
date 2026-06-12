#!/usr/bin/env python3
"""Create many orders with 2-3 order items through OrderController."""

import argparse
from pathlib import Path

import requests

from stress_test_common import COUNTRIES, BASE_URL, load_json_lines, random_customer, random_order, save_json_lines


def main() -> None:
    parser = argparse.ArgumentParser(description="Create orders through /orders.")
    parser.add_argument("-n", "--count", type=int, default=1000, help="Number of orders to create")
    parser.add_argument("-c", "--customers", default="generated_customers.jsonl", help="Optional JSONL file with customer payloads")
    parser.add_argument("-o", "--output", default="generated_orders.jsonl", help="Where to store created order identifiers")
    args = parser.parse_args()

    customers = load_json_lines(args.customers)
    if not customers:
        customers = [random_customer(country=country) for country in COUNTRIES]

    session = requests.Session()
    url = f"{BASE_URL}/orders"
    created = []

    print(f"Creating {args.count} orders at {url}")
    for i in range(args.count):
        customer = customers[i % len(customers)]
        country = COUNTRIES[i % len(COUNTRIES)]
        cust_id = customer.get("custId") or customer.get("custid")
        if not cust_id:
            raise SystemExit(f"Customer entry is missing custId/custid: {customer}")
        payload = random_order(country=country, custid=cust_id)
        resp = session.post(url, json=payload, timeout=10)
        resp.raise_for_status()
        created.append({
            "country": payload["country"],
            "custId": payload["custId"],
            "orderId": payload["orderId"],
        })
        if (i + 1) % 100 == 0 or i == args.count - 1:
            print(f"Created {i + 1}/{args.count}")

    save_json_lines(args.output, created)
    print(f"Saved created order ids to {Path(args.output).resolve()}")


if __name__ == "__main__":
    main()