# The example code below executes an insert using exec_array to create multiple rows with a single call.
#
# More details can be found in the tutorial at https://learncodeshare.net/2016/10/04/insert-crud-using-ruby-oci8/
#  section titled "Insert more than 1 row"

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

# Example code showing how to insert multiple rows with a single database call.
cursor = con.parse('INSERT INTO lcs_people(name, age, notes) VALUES (:name, :age, :notes)')
cursor.max_array_size = 2
cursor.bind_param_array(:name, %w[Sandy Suzy])
cursor.bind_param_array(:age, [31, 29])
cursor.bind_param_array(:notes, ['I like horses', 'I like rabbits'])
people_row_count = cursor.exec_array
con.commit
printf " Successfully inserted %d records\n\n", people_row_count
# End Example

get_all_rows('New Data')
