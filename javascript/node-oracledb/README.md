# Node-oracledb Examples

This directory contains [node-oracledb 2.0](https://www.npmjs.com/package/oracledb) examples.

The node-oracledb add-on for Node.js powers high performance Oracle Database applications.

[Node-oracledb documentation](https://github.com/oracle/node-oracledb/blob/master/doc/api.md)

[Issues and questions](https://github.com/oracle/node-oracledb/issues)

To run the examples:

- [Install node-oracledb](https://github.com/oracle/node-oracledb/blob/master/INSTALL.md).


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
