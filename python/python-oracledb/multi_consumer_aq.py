#------------------------------------------------------------------------------
# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#
# This software is dual-licensed to you under the Universal Permissive License
# (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
# 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
# either license.
#
# If you elect to accept the software under the Apache License, Version 2.0,
# the following applies:
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# multi_consumer_aq.py
#
# Demonstrates how to use multi-consumer advanced queuing. It makes use of a
# RAW queue created in the sample setup.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

QUEUE_NAME = "DEMO_RAW_QUEUE_MULTI"
PAYLOAD_DATA = [
    "The first message",
    "The second message",
    "The third message",
    "The fourth and final message"
]

# connect to database
connection = oracledb.connect(user=sample_env.get_main_user(),
                              password=sample_env.get_main_password(),
                              dsn=sample_env.get_connect_string())

# create a queue
queue = connection.queue(QUEUE_NAME)
queue.deqoptions.wait = oracledb.DEQ_NO_WAIT
queue.deqoptions.navigation = oracledb.DEQ_FIRST_MSG

# enqueue a few messages
with connection.cursor() as cursor:
    print("Enqueuing messages...")
    for data in PAYLOAD_DATA:
        print(data)
        queue.enqone(connection.msgproperties(payload=data))
    connection.commit()
    print()

# dequeue the messages for consumer A
with connection.cursor() as cursor:
    print("Dequeuing the messages for consumer A...")
    queue.deqoptions.consumername = "SUBSCRIBER_A"
    while True:
        props = queue.deqone()
        if not props:
            break
        print(props.payload.decode())
    connection.commit()
    print()

# dequeue the message for consumer B
with connection.cursor() as cursor:
    print("Dequeuing the messages for consumer B...")
    queue.deqoptions.consumername = "SUBSCRIBER_B"
    while True:
        props = queue.deqone()
        if not props:
            break
        print(props.payload.decode())
    connection.commit()

print("\nDone.")
