function testSODAjs()
{
 var Driver = Packages.oracle.jdbc.OracleDriver;
 var oracleDriver = new Driver();
 var url = "jdbc:default:connection:";
 var conn = oracleDriver.defaultConnection();

 var OracleRDBMSClient = Java.type("oracle.soda.rdbms.OracleRDBMSClient");
 var OracleDataSource = Java.type('oracle.jdbc.pool.OracleDataSource');

 var cl = new OracleRDBMSClient();
 var db = cl.getDatabase(conn);

 //Check and drop the named collection if it already exists
 var col = db.openCollection("MyFirstJSONCollection");
      if (col != null) col.admin().drop();

 // Create a collection with the name "MyFirstJSONCollection".
 // Note: Collection names are case-sensitive.
 // A table with the name "MyFirstJSONCollection" will be
 // created in the RDBMS to store the collection
 col = db.admin().createCollection("MyFirstJSONCollection");

 // Create a few JSON documents, representing
 // users and the number of friends they have
 var doc1 = db.createDocumentFromString(
                             "{ \"name\" : \"Alex\", \"friends\" : \"50\" }");
 var doc2 = db.createDocumentFromString(
                             "{ \"name\" : \"Mia\", \"friends\" : \"300\" }");
 var doc3 = db.createDocumentFromString(
                             "{ \"name\" : \"Gloria\", \"friends\" : \"399\" }");

 // Insert the documents into a collection, one-by-one.
 // The result documents contain auto-generated
 // keys, among other documents components (version, etc).
 // Note: SODA provides the more efficient bulk insert as well
 var resultDoc1 = col.insertAndGet(doc1);
 var resultDoc2 = col.insertAndGet(doc2);
 var resultDoc3 = col.insertAndGet(doc3);

 // Retrieve the first document using its auto-generated unique ID (aka key)
 print ("* Retrieving the first document by its key *\n");
 var fetchedDoc = col.find().key(resultDoc1.getKey()).getOne();
 print (fetchedDoc.getContentAsString());

 // Retrieve all documents representing users that have
 // 300 or more friends. Use the following query-by-example:
 // {friends : {$gte : 300}}.
 print("\n* Retrieving documents representing users with at least 300 friends *\n");
 var f = db.createDocumentFromString("{ \"friends\" : { \"$gte\" : 300 }}");

 // Get a cursor over all documents in the collection that match our query-by-example
 var c = col.find().filter(f).getCursor();

 while (c.hasNext()) {
 // Get the next document
    fetchedDoc = c.next();
    print(fetchedDoc.getContentAsString());
    print("\n")
 }

}
var output = testSODAjs();
print(output);



