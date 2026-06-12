#!/usr/bin/env python3
"""Shared helpers for simple REST stress/data-generation scripts."""

from __future__ import annotations

import json
import random
import string
import time
import uuid
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

BASE_URL = "http://localhost:8080"

COUNTRIES = [
    "Denmark", "France", "Germany", "Poland", "Spain", "United Kingdom",
    "India", "Australia", "Japan", "New Zealand", "Saudi Arabia",
    "Singapore", "Turkey",
]

FIRST_NAMES = [
    "Alice", "Bob", "Carol", "David", "Emma", "Frank", "Grace", "Henry",
    "Ivy", "Jack", "Kate", "Liam", "Mia", "Noah", "Olivia", "Paul",
    "Quinn", "Ruby", "Sophia", "Thomas", "Uma", "Victor", "Wendy", "Zoe",
]

LAST_NAMES = [
    "Anderson", "Brown", "Clark", "Davis", "Evans", "Fisher", "Garcia",
    "Harris", "Ivanov", "Johnson", "Kowalski", "Lopez", "Miller", "Novak",
    "Olsen", "Peterson", "Quincy", "Robinson", "Smith", "Taylor", "Usman",
    "Valdez", "White", "Xu", "Young", "Zimmer",
]

ORDER_STATUSES = ["NEW", "PAID", "HOLD", "DONE"]
ITEM_STATUSES = ["NEW", "HOLD", "DONE"]


def random_customer_id() -> str:
    return f"CUST-{uuid.uuid4().hex[:12].upper()}"


def random_name() -> tuple[str, str]:
    return random.choice(FIRST_NAMES), random.choice(LAST_NAMES)


def random_profile(country: str) -> str:
    loyalty = random.choice(["bronze", "silver", "gold", "platinum"])
    return json.dumps(
        {
            "country": country,
            "loyalty": loyalty,
            "segment": random.choice(["consumer", "small-business", "enterprise"]),
            "newsletter": random.choice([True, False]),
            "tags": random.sample(
                ["vip", "promo", "seasonal", "returning", "bulk-buyer"],
                k=random.randint(1, 3),
            ),
        }
    )


def random_customer(country: str | None = None) -> dict:
    country = country or random.choice(COUNTRIES)
    first_name, last_name = random_name()
    return {
        "custId": random_customer_id(),
        "firstName": first_name,
        "lastName": last_name,
        "custProfile": random_profile(country),
    }


def iso_now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%S")


def random_money(min_value: str = "5.00", max_value: str = "500.00") -> str:
    min_cents = int(Decimal(min_value) * 100)
    max_cents = int(Decimal(max_value) * 100)
    cents = random.randint(min_cents, max_cents)
    return str((Decimal(cents) / Decimal("100")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def random_order_id() -> int:
    return random.randint(100_000, 999_999_999)


def random_order(country: str, custid: str, order_id: int | None = None) -> dict:
    order_id = order_id if order_id is not None else random_order_id()
    items = []
    sum_total = Decimal("0.00")
    for item_no in range(1, random.randint(2, 3) + 1):
        price = Decimal(random_money("10.00", "250.00"))
        sum_total += price
        items.append(
            {
                "itemId": item_no,
                "price": str(price),
                "status": random.choice(ITEM_STATUSES),
            }
        )
    return {
        "country": country,
        "custId": custid,
        "orderId": order_id,
        "orderDate": iso_now(),
        "sumTotal": str(sum_total.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)),
        "status": random.choice(ORDER_STATUSES),
        "items": items,
    }


def random_text(length: int = 10) -> str:
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=length))


def save_json_lines(path: str | Path, rows: list[dict]) -> None:
    destination = Path(path)
    with destination.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row) + "\n")


def load_json_lines(path: str | Path) -> list[dict]:
    source = Path(path)
    if not source.exists():
        return []
    with source.open("r", encoding="utf-8") as handle:
        return [json.loads(line) for line in handle if line.strip()]