#Code Sample from the tutorial at https://learncodeshare.net/2015/06/02/select-crud-using-cx_oracle/
#The following code is used as the base template for the other examples.

import cx_Oracle
import os
connectString = os.getenv('dd_connect')
con = cx_Oracle.connect(connectString)

# Your code here
