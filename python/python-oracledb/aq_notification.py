# -----------------------------------------------------------------------------
# Copyright (c) 2018, 2023, Oracle and/or its affiliates.
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
# aq_notification.py
#
# Demonstrates using advanced queuing notification. Once this script is
# running, run object_aq.py in another terminal to enqueue a few messages to
# the "DEMO_BOOK_QUEUE" queue.
# -----------------------------------------------------------------------------

import time

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

registered = True


def process_messages(message):
    global registered
    print("Message type:", message.type)
    if message.type == oracledb.EVENT_DEREG:
        print("Deregistration has taken place...")
        registered = False
        return
    print("Queue name:", message.queue_name)
    print("Consumer name:", message.consumer_name)
    print("Message id:", message.msgid)


connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
    events=True,
)

sub = connection.subscribe(
    namespace=oracledb.SUBSCR_NAMESPACE_AQ,
    name="DEMO_BOOK_QUEUE",
    callback=process_messages,
    timeout=300,
)
print("Subscription:", sub)
print("--> Connection:", sub.connection)
print("--> Callback:", sub.callback)
print("--> Namespace:", sub.namespace)
print("--> Protocol:", sub.protocol)
print("--> Timeout:", sub.timeout)

while registered:
    print("Waiting for notifications....")
    time.sleep(5)
