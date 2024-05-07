# -----------------------------------------------------------------------------
# Copyright (c) 2022, 2024, Oracle and/or its affiliates.
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
#
# NAME
#
#   Dockerfile
#
# PURPOSE
#
#   Creates a container with the python-oracledb samples and a running Oracle
#   Database 23ai Free database so you can quickly try python-oracledb.
#
#   Python-oracledb is the Python database driver for Oracle Database.  See
#   https://oracle.github.io/python-oracledb/
#
# USAGE
#
#   Get an Oracle Database container (see
#   https://hub.docker.com/r/gvenzl/oracle-free):
#
#     podman pull docker.io/gvenzl/oracle-free
#
#   Create a container with the database, Python, python-oracledb and the
#   samples. Choose a password for the sample schemas and pass it as an
#   argument:
#
#     podman build -t pyo --build-arg PYO_PASSWORD=a_secret .
#
#   Start the container, which creates the database. Choose a password for the
#   privileged database users and pass it as a variable:
#
#     podman run -d --name pyo -p 1521:1521 -it -e ORACLE_PASSWORD=a_secret pyo
#
#   Log into the container:
#
#     podman exec -it pyo bash
#
#   At the first login, create the sample schema:
#
#     python setup.py
#
#   If this times out, wait a few minutes for the database to finish
#   initializing and then rerun it.
#
#   In the container, run samples like:
#
#     python bind_insert.py
#
#   Use `vim` to edit files, if required.
#
#   The database will persist across container shutdowns, but will be deleted
#   when the container is deleted.

FROM docker.io/gvenzl/oracle-free

USER root

RUN microdnf module disable python36 && \
    microdnf module enable python39 && \
    microdnf install python39 python39-pip python39-setuptools python39-wheel vim vi httpd-tools && \
    microdnf clean all

WORKDIR /samples/

RUN curl -LO https://github.com/oracle/python-oracledb/archive/refs/heads/main.zip && \
    unzip main.zip && \
    cp python-oracledb-main/samples/sample_container/setup.py . && \
    /bin/rm -rf python-oracledb-main/samples/sample_container/ python-oracledb-main/samples/sample_notebooks/ && \
    mv python-oracledb-main/samples/* . && \
    /bin/rm -rf python-oracledb-main samples main.zip && \
    cat create_schema.py >> /samples/setup.py && \
    chown -R oracle.oinstall /samples/

USER oracle

RUN python3 -m pip install oracledb Flask --user --no-warn-script-location

ARG PYO_PASSWORD

ENV PYO_SAMPLES_MAIN_USER=pythondemo
ENV PYO_SAMPLES_MAIN_PASSWORD=${PYO_PASSWORD}
ENV PYO_SAMPLES_EDITION_USER=pythoneditions
ENV PYO_SAMPLES_EDITION_PASSWORD=${PYO_PASSWORD}
ENV PYO_SAMPLES_EDITION_NAME=python_e1
ENV PYO_SAMPLES_CONNECT_STRING="localhost/freepdb1"
ENV PYO_SAMPLES_DRCP_CONNECT_STRING="localhost/freepdb1:pooled"
ENV PYO_SAMPLES_ADMIN_USER=system

# Run the samples using the default python-oracledb 'Thin' mode, if possible
ENV PYO_SAMPLES_DRIVER_MODE="thin"

# The privileged user password is set in setup.py from the "podman run"
# environment variable ORACLE_PASSWORD
#ENV PYO_SAMPLES_ADMIN_PASSWORD=
