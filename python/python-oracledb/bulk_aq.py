#------------------------------------------------------------------------------
# Copyright (c) 2019, 2022, Oracle and/or its affiliates.
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
# bulk_aq.py
#
# Demonstrates how to use bulk enqueuing and dequeuing of messages with
# advanced queuing. It makes use of a RAW queue created in the sample setup.
#------------------------------------------------------------------------------

import oracledb
import sample_env

QUEUE_NAME = "DEMO_RAW_QUEUE"
PAYLOAD_DATA = [
    "The first message",
    "The second message",
    "The third message",
    "The fourth message",
    "The fifth message",
    "The sixth message",
    "The seventh message",
    "The eighth message",
    "The ninth message",
    "The tenth message",
    "The eleventh message",
    "The twelfth and final message"
]

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

# connect to database
connection = oracledb.connect(user=sample_env.get_main_user(),
                              password=sample_env.get_main_password(),
                              dsn=sample_env.get_connect_string())

# create a queue
with connection.cursor() as cursor:
    queue = connection.queue(QUEUE_NAME)
    queue.deqoptions.wait = oracledb.DEQ_NO_WAIT
    queue.deqoptions.navigation = oracledb.DEQ_FIRST_MSG

    # dequeue all existing messages to ensure the queue is empty, just so that
    # the results are consistent
    while queue.deqone():
        pass

# enqueue a few messages
with connection.cursor() as cursor:
    print("Enqueuing messages...")
    batch_size = 6
    data_to_enqueue = PAYLOAD_DATA
    while data_to_enqueue:
        batch_data = data_to_enqueue[:batch_size]
        data_to_enqueue = data_to_enqueue[batch_size:]
        messages = [connection.msgproperties(payload=d) for d in batch_data]
        for data in batch_data:
            print(data)
        queue.enqmany(messages)
    connection.commit()

# dequeue the messages
with connection.cursor() as cursor:
    print("\nDequeuing messages...")
    batch_size = 8
    while True:
        messages = queue.deqmany(batch_size)
        if not messages:
            break
        for props in messages:
            print(props.payload.decode())
    connection.commit()
    print("\nDone.")
