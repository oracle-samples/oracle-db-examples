import java.sql.Connection;
import java.sql.DriverManager;
import oracle.sql.*;
import oracle.soda.rdbms.OracleRDBMSClient;

import oracle.soda.OracleDatabase;
import oracle.soda.OracleCursor;
import oracle.soda.OracleCollection;
import oracle.soda.OracleDocument;
import oracle.soda.OracleException;

import java.util.Properties;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

public class testSODA {
    public static void main(String[] args) {

        // SODA works on top of a regular JDBC connection.

        Connection conn = null;

        try {
            /*
             * Where is your code running: in the database or outside?
             */
            if (System.getProperty("oracle.jserver.version") != null)
             {
             /*
              * You are in the database, already connected, use the default connection
              *
              */
                 OracleDataSource ods = new OracleDataSource();
                 ods.setURL("jdbc:default:connection");
                 conn = ods.getConnection();
              }
             else {
              /*
               * You are not in the database, you need to connect thru the client driver
               */
                // Set up the connection string: replace hostName, port, and serviceName
                // with the info for your Oracle RDBMS instance
                String url = "jdbc:oracle:thin:@//hostName:port/serviceName";

                Properties props = new Properties();
                // Replace with your schemaName and password
                props.setProperty("user", "schemaName");
                props.setProperty("password", "password");

                conn = (OracleConnection) DriverManager.getConnection(url, props);
            }
            // Get an OracleRDBMSClient - starting point of SODA for Java application
            OracleRDBMSClient cl = new OracleRDBMSClient();

            // Get a database
            OracleDatabase db = cl.getDatabase(conn);

            //Check whether the named collection already exists or not
            OracleCollection col = db.openCollection("MyFirstJSONCollection");
            if (col != null) col.admin().drop();

            // Create a collection with the name "MyFirstJSONCollection".
            // Note: Collection names are case-sensitive.
            // A table with the name "MyFirstJSONCollection" will be
            // created in the RDBMS to store the collection
            col = db.admin().createCollection("MyFirstJSONCollection");

            // Create a few JSON documents, representing
            // users and the number of friends they have
            OracleDocument doc1 =
                    db.createDocumentFromString(
                            "{ \"name\" : \"Alex\", \"friends\" : \"50\" }");

            OracleDocument doc2 =
                    db.createDocumentFromString(
                            "{ \"name\" : \"Mia\", \"friends\" : \"300\" }");

            OracleDocument doc3 =
                    db.createDocumentFromString(
                            "{ \"name\" : \"Gloria\", \"friends\" : \"399\" }");

            // Insert the documents into a collection, one-by-one.
            // The result documents contain auto-generated
            // keys, among other documents components (version, etc).
            // Note: SODA provides the more efficient bulk insert as well
            OracleDocument resultDoc1 = col.insertAndGet(doc1);
            OracleDocument resultDoc2 = col.insertAndGet(doc2);
            OracleDocument resultDoc3 = col.insertAndGet(doc3);

            // Retrieve the first document using its auto-generated
            // unique ID (aka key)
            System.out.println ("* Retrieving the first document by its key *\n");

            OracleDocument fetchedDoc = col.find().key(resultDoc1.getKey()).getOne();

            System.out.println (fetchedDoc.getContentAsString());

            // Retrieve all documents representing users that have
            // 300 or more friends. Use the following query-by-example:
            // {friends : {$gte : 300}}.
            System.out.println ("\n* Retrieving documents representing users with" +
                    " at least 300 friends *\n");

            OracleDocument f = db.createDocumentFromString(
                    "{ \"friends\" : { \"$gte\" : 300 }}");

            OracleCursor c = null;

            try {
                // Get a cursor over all documents in the collection
                // that match our query-by-example
                c = col.find().filter(f).getCursor();

                while (c.hasNext()) {
                    // Get the next document
                    fetchedDoc = c.next();

                    System.out.println (fetchedDoc.getContentAsString());
                }
            }
            finally {
                // Important: you must close the cursor to release resources!
                if (c != null) {
                    c.close();
                }
            }

            // Drop the collection, deleting the table backing
            // it and collection metadata
            if (args.length > 0 && args[0].equals("drop")) {
                col.admin().drop();
                System.out.println ("\n* Collection dropped *");
            }
        }
        catch (Exception e) {
            e.printStackTrace();
        }
        finally {
            if (conn != null) {
                try {
                    conn.close();
                }
                catch (Exception e) {
                }
            }
        }
    }
}