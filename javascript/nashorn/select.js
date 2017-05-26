var selectQuery = function(id)
{
   var Driver = Packages.oracle.jdbc.OracleDriver;
   var oracleDriver = new Driver();
   var url = "jdbc:default:connection:";
   var output = "";
   var connection = oracleDriver.defaultConnection();
   var prepStmt;

   // Prepare statement
    if(id == 'all') {
       prepStmt = connection.prepareStatement("SELECT a.data FROM employees a");
      } else {
       prepStmt = connection.prepareStatement("SELECT a.data FROM employees a WHERE a.data.EmpId = ?");
       prepStmt.setInt(1, id);
       }

   // execute Query
	var resultSet = prepStmt.executeQuery();

   // display results
	while(resultSet.next()) {
		output = output + resultSet.getString(1) + "<br>";
	}

   // cleanup
    resultSet.close();
    prepStmt.close();
    connection.close();
    return output;
}
