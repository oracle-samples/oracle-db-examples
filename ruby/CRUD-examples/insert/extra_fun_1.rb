# Code Sample from the tutorial at https://learncodeshare.net/2016/10/04/insert-crud-using-ruby-oci8/
#  section titled "Extra Fun 1 & 2"
# Using the base template, the example code executes a simple insert using positional bind variables.
#  The same statement is executed twice each using different bind variable values.

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

statement = 'insert into lcs_people(name, age, notes) values (:name, :age, :notes)'
cursor = con.parse(statement)
cursor.bind_param(:name, 'Rob')
cursor.bind_param(:age, 37)
cursor.bind_param(:notes, 'I like snakes')
cursor.exec

cursor.bind_param(:name, 'Cheryl')
cursor.bind_param(:age, 41)
cursor.bind_param(:notes, 'I like monkeys')
cursor.exec
con.commit

get_all_rows('New Data')
