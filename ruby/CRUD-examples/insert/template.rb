# The following code is used as the base template for the other examples.
#  It is intended to be helper code not part of the examples.
# Code Sample from the tutorial at https://learncodeshare.net/2016/08/26/basic-crud-operations-using-ruby-oci8/
#  section titled "Boilerplate template"

require 'oci8'

def get_all_rows(label)
  connectString = ENV['DB_CONNECT'] # The environment variable for the connect string: DB_CONNECT=user/password@database
  con = OCI8.new(connectString)

  # Query all rows
  statement = 'select id, name, age, notes from lcs_people order by id'
  cursor = con.parse(statement)
  cursor.exec
  printf " %s:\n", label
  cursor.fetch do |row|
    printf "  Id: %d, Name: %s, Age: %d, Notes: %s\n", row[0], row[1], row[2], row[3]
  end
  printf "\n"
end

connectString = ENV['DB_CONNECT'] # The environment variable for the connect string: DB_CONNECT=user/password@database
con = OCI8.new(connectString)

get_all_rows('Original Data')

# Your code here

get_all_rows('New Data')
