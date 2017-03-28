var selectQuery = function(id)
{
   var Driver = Packages.oracle.jdbc.OracleDriver;
   var oracleDriver = new Driver();
   var url = "jdbc:default:connection:";
   var query = "";
   var output = "";
   if(id == 'all') {
    query ="SELECT a.data FROM employees a";
   } else {
       query ="SELECT a.data FROM employees a WHERE a.data.EmpId=" + id;
   }
   var connection = oracleDriver.defaultConnection();
   // Prepare statement
   var preparedStatement = connection.prepareStatement(query);
   // execute Query
    var resultSet = preparedStatement.executeQuery();   
   // display results
   while(resultSet.next()) {
   output = output + resultSet.getString(1) + " ";
   }   
    // cleanup
    resultSet.close();
    preparedStatement.close();
    connection.close();
    return output;
  }