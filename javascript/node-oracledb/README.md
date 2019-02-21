# Node-oracledb Examples

This directory contains [node-oracledb 3.1](https://www.npmjs.com/package/oracledb) examples.

The node-oracledb add-on for Node.js powers high performance Oracle Database applications.

[Node-oracledb documentation](https://oracle.github.io/node-oracledb/doc/api.html)

[Issues and questions](https://github.com/oracle/node-oracledb/issues)

Issues and questions about node-oracledb can be posted on
[GitHub](https://github.com/oracle/node-oracledb/issues) or
[Slack](https://node-oracledb.slack.com/) ([link to join
Slack](https://node-oracledb.slack.com/join/shared_invite/enQtNDU4Mjc2NzM5OTA2LTdkMzczODY3OGY3MGI0Yjk3NmQ4NDU4MTI2OGVjNTYzMjE5OGY5YzVkNDY4MWNkNjFiMDM2ZDMwOWRjNWVhNTg).

To run the examples:

- [Install node-oracledb](https://oracle.github.io/node-oracledb/INSTALL.html).


- Use `demo.sql` to create schema objects used by the samples.  For
  example, to load them in the HR schema run:

  ```
  sqlplus hr
  SQL> @demo.sql
  ```

- Edit `dbconfig.js` and set your username and the database
connection string:

  ```
  module.exports = {
      user: "hr",
      password: process.env.NODE_ORACLEDB_PASSWORD,
      connectString:"localhost/orclpdb"
  };
  ```

- Set the environment variable `NODE_ORACLEDB_PASSWORD` to your database schema password.

  On Windows:
  ```
  set NODE_ORACLEDB_PASSWORD=...
  ```

  On Linux:
  ```
  export NODE_ORACLEDB_PASSWORD=...
  ```

- Then run the samples like:

  ```
  node select1.js
  ```

The demonstration objects can be dropped with `demodrop.sql`:

  ```
  sqlplus hr/welcome@localhost/orclpdb @demodrop.sql
  ```
