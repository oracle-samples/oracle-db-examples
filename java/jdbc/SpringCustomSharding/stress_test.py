#!/usr/bin/env python3
"""Simple multithreaded stress test for http://localhost:8080/metadata/<key>.

Each worker thread repeatedly picks a random sharding key and fires either a
GET or a POST at the metadata endpoint, then reports basic statistics.
"""

import argparse
import random
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor

import requests

BASE_URL = "http://localhost:8080/metadata"

KEYS = [
    "Denmark", "France", "Germany", "Poland", "Spain", "United Kingdom",
    "India", "Australia", "Japan", "New Zealand", "Saudi Arabia",
    "Singapore", "Turkey",
]

METHODS = ["GET", "POST"]


# Shared statistics, guarded by a lock.
stats_lock = threading.Lock()
stats = {
    "total": 0,
    "ok": 0,
    "errors": 0,
    "status_counts": Counter(),
    "latency_sum": 0.0,
}


def record(status_code, latency, ok):
    with stats_lock:
        stats["total"] += 1
        stats["latency_sum"] += latency
        if ok:
            stats["ok"] += 1
            stats["status_counts"][status_code] += 1
        else:
            stats["errors"] += 1


# Serialize stdout writes so concurrent threads don't interleave lines.
print_lock = threading.Lock()


def log_line(text):
    with print_lock:
        print(text, flush=True)


def do_request(session, method, key):
    url = f"{BASE_URL}/{key}"
    start = time.perf_counter()
    try:
        resp = session.request(method, url, timeout=10)
        latency = time.perf_counter() - start
        record(resp.status_code, latency, ok=True)
        body = resp.text.strip()
        log_line(f"{method} {key} -> {resp.status_code} | {body}")
    except requests.RequestException as exc:
        latency = time.perf_counter() - start
        record(str(exc), latency, ok=False)
        log_line(f"{method} {key} -> ERROR | {exc}")


def worker(stop_event, requests_per_thread=None):
    """Run requests until stop_event is set or the per-thread quota is hit."""
    session = requests.Session()
    count = 0
    while not stop_event.is_set():
        method = random.choice(METHODS)
        key = random.choice(KEYS)
        do_request(session, method, key)
        count += 1
        if requests_per_thread is not None and count >= requests_per_thread:
            break


def main():
    parser = argparse.ArgumentParser(description="Stress test the metadata endpoint.")
    parser.add_argument("-t", "--threads", type=int, default=10,
                        help="Number of concurrent threads (default: 10)")
    parser.add_argument("-d", "--duration", type=float, default=10.0,
                        help="Test duration in seconds (default: 10)")
    parser.add_argument("-n", "--requests-per-thread", type=int, default=None,
                        help="If set, each thread stops after this many requests "
                             "(overrides duration)")
    args = parser.parse_args()

    stop_event = threading.Event()
    print(f"Starting stress test: {args.threads} threads, "
          f"{'until ' + str(args.requests_per_thread) + ' req/thread' if args.requests_per_thread else str(args.duration) + 's'}")

    start = time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.threads) as pool:
        futures = [
            pool.submit(worker, stop_event, args.requests_per_thread)
            for _ in range(args.threads)
        ]

        if args.requests_per_thread is None:
            # Run for the requested duration, then signal threads to stop.
            try:
                time.sleep(args.duration)
            except KeyboardInterrupt:
                pass
            stop_event.set()

        try:
            for f in futures:
                f.result()
        except KeyboardInterrupt:
            stop_event.set()

    elapsed = time.perf_counter() - start

    # Report.
    with stats_lock:
        total = stats["total"]
        ok = stats["ok"]
        errors = stats["errors"]
        latency_sum = stats["latency_sum"]
        status_counts = dict(stats["status_counts"])

    print("\n=== Results ===")
    print(f"Elapsed:        {elapsed:.2f}s")
    print(f"Total requests: {total}")
    print(f"Successful:     {ok}")
    print(f"Errors:         {errors}")
    if total:
        print(f"Throughput:     {total / elapsed:.1f} req/s")
        print(f"Avg latency:    {latency_sum / total * 1000:.1f} ms")
    print(f"Status codes:   {status_counts}")


if __name__ == "__main__":
    main()
