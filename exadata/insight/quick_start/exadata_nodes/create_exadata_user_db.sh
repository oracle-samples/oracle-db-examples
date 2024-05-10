#!/bin/bash

## Run as root on each database server (physical and virtual host)

dbmcli -e CREATE ROLE realtime_collector
dbmcli -e GRANT PRIVILEGE LIST ON METRICSTREAM ALL ATTRIBUTES WITH ALL OPTIONS TO ROLE realtime_collector
dbmcli -e CREATE USER realtime_collector PASSWORD=\"Sup3rS3cr3tP@ssword\"
dbmcli -e GRANT ROLE realtime_collector to user realtime_collector
