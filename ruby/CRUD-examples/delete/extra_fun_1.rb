# The example code below executes a simple delete using named bind variables.
# Code Sample from the tutorial at https://learncodeshare.net/2016/11/09/delete-crud-using-ruby-oci8/
#  section titled "Extra Fun 1"

require 'oci8'

def get_all_rows(label, data_type = 'people')
  connectString = ENV['DB_CONNECT'] # The environment variable for the connect string: DB_CONNECT=user/password@database
  con = OCI8.new(connectString)

  # Query all rows
  statement = 'select id, name, age, notes from lcs_people order by id'

  if data_type == 'pets'
    statement = 'select id, name, owner, type from lcs_pets order by owner, id'
  end

  cursor = con.parse(statement)
  cursor.exec
  printf " %s:\n", label
  cursor.fetch do |row|
    if data_type == 'people'
      printf " Id: %d, Name: %s, Age: %d, Notes: %s\n", row[0], row[1], row[2], row[3]
    else
      printf " Id: %d, Name: %s, Owner: %d, Type: %s\n", row[0], row[1], row[2], row[3]
    end
  end
  printf "\n"
end

connectString = ENV['DB_CONNECT'] # The environment variable for the connect string: DB_CONNECT=user/password@database
con = OCI8.new(connectString)

get_all_rows('Original Data', 'pets')

# Example code showing a simple delete using named bind variables.
statement = 'delete from lcs_pets where type = :type'
cursor = con.parse(statement)
cursor.bind_param(:type, 'bird')
cursor.exec
con.commit
# End Example

get_all_rows('New Data', 'pets')
