# python-oracledb Samples in a Container

This Dockerfile creates a container with python-oracledb samples and a running
Oracle Database.

It has been tested in an Oracle Linux 8 environment using 'podman', but
'docker' should work too.

## Usage

- Get an Oracle Database container (see
  https://hub.docker.com/r/gvenzl/oracle-xe):

  ```
  podman pull docker.io/gvenzl/oracle-xe:21-slim
  ```

- Create a container with the database, Python, python-oracledb and the
  samples. Choose a password for the sample schemas and pass it as an argument:

  ```
  podman build -t pyo --build-arg PYO_PASSWORD=a_secret .
  ```

- Start the container, which creates the database. Choose a password for the
  privileged database users and pass it as a variable:

  ```
  podman run -d --name pyo -p 1521:1521 -it -e ORACLE_PASSWORD=a_secret_password pyo
  ```

- Log into the container:

  ```
  podman exec -it pyo bash
  ```

- At the first login, create the sample schema:

  ```
  python setup.py
  ```

  The schema used can be seen in `sql/create_schema.sql`

- In the container, run samples like:

  ```
  python bind_insert.py
  ```

  Use `vim` to edit files, if required.

The database will persist across container shutdowns, but will be deleted when
the container is deleted.
