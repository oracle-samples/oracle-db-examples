# Node-oracledb Examples

This directory contains [node-oracledb 3.0](https://www.npmjs.com/package/oracledb) examples.

The node-oracledb add-on for Node.js powers high performance Oracle Database applications.

[Node-oracledb documentation](https://oracle.github.io/node-oracledb/doc/api.html)

[Issues and questions](https://github.com/oracle/node-oracledb/issues)

Issues and questions about node-oracledb can be posted on
[GitHub](https://github.com/oracle/node-oracledb/issues) or
[Slack](https://node-oracledb.slack.com/) ([link to join
Slack](https://join.slack.com/t/node-oracledb/shared_invite/enQtNDI4NTUyNjMzMDA5LWRiZWRkZjQ3NjBhNDUwOGJlNDFiZWJhZTIzYTJkMWQ5N2UwNTg5NzNmNmY1YmZjZGYxNmRhOTkyOTlhMmViNjY)).

To run the examples:

- [Install node-oracledb](https://oracle.github.io/node-oracledb/INSTALL.html).


- Use `demo.sql` to create schema objects used by the samples.  For
  example, to load them in the HR schema run:

  ```
  sqlplus hr/welcome@localhost/orclpdb @demo.sql
  ```

- Edit `dbconfig.js` and set your username, password and the database
connection string:

  ```
  module.exports = {
      user: "hr",
      password: "welcome",
      connectString:"localhost/orclpdb"
  };

  ```

- Then run the samples like:

  ```
  node select1.js
  ```

The demonstration objects can be dropped with `demodrop.sql`:

  ```
  sqlplus hr/welcome@localhost/orclpdb @demodrop.sql
  ```
