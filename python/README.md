# Python-oracledb  Examples

This directory contains samples for python-oracledb, the Python driver for
Oracle Database.

1.  The schemas and SQL objects that are referenced in the samples can be
    created by running the Python script
    [create_schema.py](https://github.com/oracle-samples/oracle-db-examples/blob/main/python/create_schema.py). The
    script requires SYSDBA privileges and will prompt for these credentials as
    well as the names of the schemas and edition that will be created, unless a
    number of environment variables are set as documented in the Python script
    [sample_env.py](https://github.com/oracle-samples/oracle-db-examples/blob/main/python/sample_env.py). Run
    the script using the following command:

        python create_schema.py

2.  Run a Python script, for example:

        python query.py

3.  After running python-oracledb samples, the schemas and SQL objects can be
    dropped by running the Python script
    [drop_schema.py](https://github.com/oracle-samples/oracle-db-examples/blob/main/python/drop_schema.py). The
    script requires SYSDBA privileges and will prompt for these credentials as
    well as the names of the schemas and edition that will be dropped, unless a
    number of environment variables are set as documented in the Python script
    [sample_env.py](https://github.com/oracle-samples/oracle-db-examples/blob/main/python/sample_env.py). Run
    the script using the following command:

        python drop_schema.py

## About python-oracledb

- Python-oracledb is the new name for Oracle's popular Python cx_Oracle driver
  for Oracle Database.

- Python-oracledb 1.0 is a new major release - the successor to cx_Oracle 8.3.

- Python-oracledb is simple and small to install — under 15 MB (including
  Python package dependencies): `pip install oracledb`

- Python-oracledb is now a Thin driver by default - it connects directly to
  Oracle Database without always needing Oracle Client libraries.

- Python-oracledb has comprehensive functionality conforming to the Python
  Database API v2.0 Specification, with many additions and just a couple of
  exclusions.

- A "Thick" mode can be optionally enabled by an application call. This mode
  has similar functionality to cx_Oracle and supports Oracle Database features
  that extend the Python DB API. To use this mode, the widely used and tested
  Oracle Client libraries such as from Oracle Instant Client must be installed
  separately.

- Python-oracledb runs on many platforms including favorites like Linux, macOS
  and Windows. It can also be used on platforms where Oracle Client libraries
  are not available (such as Apple M1, Alpine Linux, or IoT devices), or where
  the client libraries are not easily installed (such as some cloud
  environments).

## Resources

Home page: [oracle.github.io/python-oracledb/](https://oracle.github.io/python-oracledb/)

Quick start: [Quick Start python-oracledb Installation](https://python-oracledb.readthedocs.io/en/latest/user_guide/installation.html#quick-start-python-oracledb-installation)

Documentation: [python-oracle.readthedocs.io/en/latest/index.html](https://python-oracle.readthedocs.io/en/latest/index.html)

PyPI: [pypi.org/project/oracledb/](https://pypi.org/project/oracledb/)

Source: [github.com/oracle/python-oracledb](https://github.com/oracle/python-oracledb)

Upgrading: [Upgrading from cx_Oracle 8.3 to python-oracledb](https://python-oracledb.readthedocs.io/en/latest/user_guide/appendix_c.html#upgrading-from-cx-oracle-8-3-to-python-oracledb)
