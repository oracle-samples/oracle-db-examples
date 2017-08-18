# The example code below executes a simple insert using named bind variables.
#  A cursor variable is used to accept the insert statements returning value.  This value is then
#  used as the parent key value to insert a child record.
# Code Sample from the tutorial at https://learncodeshare.net/2016/10/04/insert-crud-using-ruby-oci8/
#  section titled "Returning data after an insert"

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
statement = 'insert into lcs_people(name, age, notes) values (:name, :age, :notes) returning id into :id'
cursor = con.parse(statement)
cursor.bind_param(:name, 'Sandy')
cursor.bind_param(:age, 31)
cursor.bind_param(:notes, 'I like horses')
cursor.bind_param(:id, Integer)
cursor.exec

new_id = cursor[:id]

statement = 'insert into lcs_pets (name, owner, type) values (:name, :owner, :type)'
cursor = con.parse(statement)
cursor.bind_param(:name, 'Big Red')
cursor.bind_param(:owner, new_id)
cursor.bind_param(:type, 'horse')
cursor.exec

con.commit

printf " Our new value is: %d\n", new_id

statement = 'select name, owner, type from lcs_pets where owner = :owner'
cursor = con.parse(statement)
cursor.bind_param(:owner, new_id)
cursor.exec
printf "\n Sandy\'s pets:\n"
cursor.fetch do |row|
  printf " Name: %s, Owner: %d, Type: %s\n", row[0], row[1], row[2]
end
printf "\n"
# End Example

get_all_rows('New Data')
