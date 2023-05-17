require 'oci8'

con = OCI8.new(ENV['OADB_USER'],
               ENV['OADB_PW'],
               ENV['OADB_SERVICE']);

statement = "select 'Connected to Oracle Autonomous Transaction Processing from Ruby!' 
from dual";
cursor = con.parse(statement)
cursor.exec
cursor.fetch() {|row|
  printf "%s\n", row[0]
}