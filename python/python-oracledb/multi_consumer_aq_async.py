# -----------------------------------------------------------------------------
# Copyright (c) 2025, Oracle and/or its affiliates.
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
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# multi_consumer_aq.py
#
# Demonstrates how to use multi-consumer advanced queuing. It makes use of a
# RAW queue created in the sample setup.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env

QUEUE_NAME = "DEMO_RAW_QUEUE_MULTI"
PAYLOAD_DATA = [
    "The first message",
    "The second message",
    "The third message",
    "The fourth and final message",
]


async def main():

    # connect to database
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
    )

    # create a queue
    queue = connection.queue(QUEUE_NAME)
    queue.deqoptions.wait = oracledb.DEQ_NO_WAIT
    queue.deqoptions.navigation = oracledb.DEQ_FIRST_MSG

    # enqueue a few messages
    print("Enqueuing messages...")
    for data in PAYLOAD_DATA:
        print(data)
        await queue.enqone(connection.msgproperties(payload=data))
    await connection.commit()
    print()

    # dequeue the messages for consumer A
    print("Dequeuing the messages for consumer A...")
    queue.deqoptions.consumername = "SUBSCRIBER_A"
    while True:
        props = await queue.deqone()
        if not props:
            break
        print(props.payload.decode())
    await connection.commit()
    print()

    # dequeue the message for consumer B
    print("Dequeuing the messages for consumer B...")
    queue.deqoptions.consumername = "SUBSCRIBER_B"
    while True:
        props = await queue.deqone()
        if not props:
            break
        print(props.payload.decode())
    await connection.commit()
    print("\nDone.")


asyncio.run(main())
