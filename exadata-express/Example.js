/*----------------------------------------------------------------------

Example.js

Demonstrate how to perform a database insert and query with Node.js in
Oracle Database Cloud services such as Exadata Express, Autonomous
Transaction Processing, Autonomous Data Warehouse, and others.

Before running this script:
 - Install Node.js and node-oracledb
 - Install Oracle Instant Client
 - Download and install the cloud service wallet
 - Modify the getConnection() call below to use the credentials for your database.
See your cloud service's documentation for details.

----------------------------------------------------------------------*/

var oracledb = require('oracledb');

async function run() {
  let connection;

  try {

    let sql, binds, options, result;

    connection = await oracledb.getConnection(  {
      user          : 'username',
      password      : 'password',
      connectString : 'connect_string'
    });

    // Create a table

    await connection.execute(
      `BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE mycloudtab';
         EXCEPTION
         WHEN OTHERS THEN
           IF SQLCODE NOT IN (-00942) THEN
             RAISE;
           END IF;
       END;`);

    await connection.execute(
      `CREATE TABLE mycloudtab (id NUMBER, data VARCHAR2(20))`);

    // Insert some data

    sql = `INSERT INTO mycloudtab VALUES (:1, :2)`;
    binds = [ [101, "Alpha" ], [102, "Beta" ], [103, "Gamma" ] ];
    options = {
      autoCommit: true,
      bindDefs: [
        { type: oracledb.NUMBER },
        { type: oracledb.STRING, maxSize: 20 }
      ]
    };

    await connection.executeMany(sql, binds, options);

    // Query the data

    sql = `SELECT * FROM mycloudtab`;
    binds = {};
    options = {};

    result = await connection.execute(sql, binds, options);
    console.log(result.rows);

  } catch (err) {
    console.error(err);
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}

run();
