This example demonstrates hint usage in ADWC.

Create a test user using the *user.sql* script.

To run the entire example, log in ADWC using the LOW consumer group and then:

*  @tabs - Create test tables (note that it drops tables TABLE1 and TABLE2)
*  @q1   - The default query plan
*  @q2   - The query includes hints that are not obeyed
*  @q3   - The ALTER SESSION allows the optimizer to use hints

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create tables. For use on test databases.
