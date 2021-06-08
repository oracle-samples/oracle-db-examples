This example demonstrates how to connect to an Oracle Cloud Autonomous Transaction Processing Database (ATP).  The same steps can be used to connect to an Autonomous Data Warehouse.
## Prerequisites
- Have an Oracle ATP instance provisioned and running. (If you don’t have a current instance, you can [sign up for a free trial](https://www.oracle.com/cloud/free/).)
  The examples will use an instance named DemoATP.
- Have a database schema and password created that you can use for testing.
- Have access to the Oracle ATP service panel or have someone with access available to help.
- Download and install Oracle Database Instant Client.
- (Optional but a good idea) Have Oracle SQLcl installed to verify the connection in a neutral environment.

## Download Client Credentials (Oracle Wallet)
With the prerequisites complete, download the client credentials for your Oracle ATP Database instance.
1. Go to the Service Console for your ATP instance.
1. Click Administration.
1. Click the Download Client Credentials (Wallet) button.
1. Enter a password, and click Download.
   Remember this password. If you lose it, you will need to download a new credentials file.
1. Save the file in a secure location. Remember, this file can be used to access your database, so keep it secure.
1. Create a directory, and extract the client credentials zip file into that directory. You should now have the following files:
   - cwallet.sso
   - ewallet.p12
   - keystore.jks
   - ojdbc.properties
   - sqlnet.ora
   - tnsnames.ora
   - truststore.jks
1. Edit the sqlnet.ora file. Set the DIRECTORY value to the directory used in step 6, for example: 
(DIRECTORY="/home/demouser/projects/ATP/Wallet_Creds")

The tnsnames.ora file includes auto-generated TNS Name values. You can refer to the documentation for an explanation of when to use each of these.
The examples will use the DemoATP_TP TNS Name value.

## Test the Connection: Optional but Recommended
Now test the connection from your Oracle SQLcl or Oracle SQL Developer tool.

### Oracle SQLcl.
To test the connection from Oracle SQLcl, do the following:

1. Start Oracle SQLcl in nolog mode.

   ```
   sql /nolog
   ```
1. Set the location of your credentials zip file.
   ```
   set cloudconfig /home/demouser/projects/ATP/Wallet_Creds/client_credentials.zip
   Operation is successfully completed.
   Using temp directory:/tmp/oracle_cloud_config903805845690230771
   ```
1. Connect with a schema/password that is safe for testing.
   ```
   connect myschema/mypassword@DemoATP_TP
   Connected.
   ```
1. If all goes well, you should now be connected and able to run a test query.
   ```
   select 'Connected to Oracle Autonomous Transaction Processing from SQLcl!' "Test It" from dual;
   Test It                                                          
   -----------------------------------------------------------------
   Connected to Oracle Autonomous Transaction Processing from SQLcl!
   ```
1. Exit Oracle SQLcl.
   ```
   exit
   
   Disconnected from Oracle Database 18c Enterprise Edition 
   Release 18.0.0.0.0 – Production
   Version 18.4.0.0.0
   ```
## Connect From Ruby

1. Download and install the ruby-oci8 driver.
1. Set the following environment variables.
   (Linux example shown, you may need to adjust for your OS)
   ```
   export TNS_ADMIN="/home/demouser/projects/ATP/Wallet_Creds"
   export OADB_USER='demo'
   export OADB_PW='demoPassword'
   export OADB_SERVICE='DemoATP_TP'
   ```
1. Review the ruby-demo.rb file.
1. Run the ruby-demo.rb file in Ruby with the following command:
   ```
   ruby ruby-demo.rb
   ```
The following response confirms your connection from Ruby to Oracle Autonomous Transaction Processing:
```
Connected to Oracle Autonomous Transaction Processing from Ruby!
```