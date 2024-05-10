#!/bin/bash

podman run --name=realtime_prometheus -v prometheusdata:/prometheus -d -p 9090:9090 realtime_prometheus
