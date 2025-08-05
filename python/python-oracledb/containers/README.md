# python-oracledb Samples in a Container

This Dockerfile creates a container with the python-oracledb samples and a
running Oracle Database 23ai Free database so you can quickly try
python-oracledb.

It has been tested on Oracle Linux 8 using 'podman', and on Apple Silicon with
'docker' under colima.

## Usage

- Get an Oracle Database container (see
  https://hub.docker.com/r/gvenzl/oracle-free):

  The steps below use 'podman', but 'docker' will also work.

  ```
  podman pull docker.io/gvenzl/oracle-free
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

  If this times out, wait a few minutes for the database to finish initializing
  and then rerun it.

  The schema used can be seen in `sql/create_schema.sql`

- In the container, run samples like:

  ```
  python bind_insert.py
  ```

  Use `vim` to edit files, if required.

The database will persist across container shutdowns, but will be deleted when
the container is deleted.
