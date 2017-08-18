# The example code below executes a simple query, uses fetch to retrieve the data
#  and displays the results.
# Code Sample from the tutorial at https://learncodeshare.net/2016/09/09/select-crud-using-ruby-oci8/
#  section titled "Simple query"

require 'oci8'
connectString = ENV['DB_CONNECT'] # The environment variable for the connect string: DB_CONNECT=user/password@database
con = OCI8.new(connectString)

# Example code showing a simple query for all rows.
con = OCI8.new(connectString)
statement = 'select id, name, age, notes from lcs_people'
cursor = con.parse(statement)
cursor.exec
cursor.fetch do |row|
  print row
end
# End Example
