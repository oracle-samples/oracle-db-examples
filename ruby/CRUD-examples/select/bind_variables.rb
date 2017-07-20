# Code Sample from the tutorial at https://learncodeshare.net/2016/09/09/select-crud-using-ruby-oci8/
#  section titled "Select specific rows"
# Using the base template, the example code executes a simple query using named bind variables,
#  uses fetchall to retrieve the data and displays the results.

require 'oci8'
connectString = ENV['DB_CONNECT'] # The environment variable for the connect string: DB_CONNECT=user/password@database
con = OCI8.new(connectString)

# Query for Kim
person_name = 'Kim'
statement = 'select id, name, age, notes from lcs_people where name=:name'
cursor = con.parse(statement)
cursor.bind_param('name', person_name)
cursor.exec
cursor.fetch do |row|
  printf "Id: %d, Name: %s, Age: %d, Notes: %s\n", row[0], row[1], row[2], row[3]
end