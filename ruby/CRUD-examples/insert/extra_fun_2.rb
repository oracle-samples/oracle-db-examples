# Code Sample from the tutorial at https://learncodeshare.net/2016/10/04/insert-crud-using-ruby-oci8/
#  section titled "Extra Fun 1 & 2"
# Using the base template, the example code executes a simple insert using positional bind variables.
#  The get_all_rows function is modified to use a second connection to show how the data is seen
#  by different connections before and after a commit.

require 'oci8'

def get_all_rows(label, con)
  # Query all rows
  statement = 'select id, name, age, notes from lcs_people order by id'
  cursor = con.parse(statement)
  cursor.exec
  printf " %s:\n", label
  cursor.fetch do |row|
    printf " Id: %d, Name: %s, Age: %d, Notes: %s\n", row[0], row[1], row[2], row[3]
  end
  printf "\n"
end

connectString = ENV['DB_CONNECT'] # The environment variable for the connect string: DB_CONNECT=user/password@database
con = OCI8.new(connectString)
con2 = OCI8.new(connectString)

get_all_rows('Original Data', con)

statement = 'insert into lcs_people(name, age, notes) values (:name, :age, :notes)'
cursor = con.parse(statement)
cursor.bind_param(:name, 'Suzy')
cursor.bind_param(:age, 31)
cursor.bind_param(:notes, 'I like rabbits')
cursor.exec

get_all_rows('New connection after insert', con2)
get_all_rows('Same connection', con)

con.commit

get_all_rows('New connection after commit', con2)
get_all_rows('New Data', con)
