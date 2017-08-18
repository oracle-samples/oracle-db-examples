# The example code below executes a simple insert using named bind variables.
#  Cursor variables are used to accept the insert statement's returning values.
# Code Sample from the tutorial at https://learncodeshare.net/2016/10/04/insert-crud-using-ruby-oci8/
#  section titled "Extra Fun 3"

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

# Example code showing how to work with returning vales from the insert.
statement = 'insert into lcs_people(name, age, notes) values (:name, :age, :notes) returning id, name into :id, :name_out'
cursor = con.parse(statement)
cursor.bind_param(:name, 'Sandy')
cursor.bind_param(:age, 31)
cursor.bind_param(:notes, 'I like horses')
cursor.bind_param(:id, Integer)
cursor.bind_param(:name_out, String)
cursor.exec

new_id = cursor[:id]
name_out = cursor[:name_out]

con.commit

printf " Our new id is: %d name: %s\n\n", new_id, name_out
# End Example

get_all_rows('New Data')
