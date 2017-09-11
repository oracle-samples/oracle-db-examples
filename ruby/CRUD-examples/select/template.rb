# The following code is used as the base template for the other examples.
#  It is intended to be helper code not part of the examples.
# Code Sample from the tutorial at https://learncodeshare.net/2016/09/09/select-crud-using-ruby-oci8/

require 'oci8'
connectString = ENV['DB_CONNECT'] # The environment variable for the connect string: DB_CONNECT=user/password@database
con = OCI8.new(connectString)

# Your code here
