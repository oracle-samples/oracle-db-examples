# Code Sample from the tutorial at https://learncodeshare.net/2016/09/09/select-crud-using-ruby-oci8/
#  section titled "Simple query"
# Using the base template, the example code executes a simple query, uses fetchall to retrieve the data
#  and displays the results.

require 'oci8'
connectString = ENV['DB_CONNECT'] # The environment variable for the connect string: DB_CONNECT=user/password@database
con = OCI8.new(connectString)

# Query all rows
con = OCI8.new(connectString)
statement = 'select id, name, age, notes from lcs_people'
cursor = con.parse(statement)
cursor.exec
cursor.fetch do |row|
  print row
end
