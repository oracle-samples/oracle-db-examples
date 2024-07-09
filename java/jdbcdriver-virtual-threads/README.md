# Java - Oracle Developers on Medium.com
[Introduction to Oracle JDBC 21c Driver Support for Virtual Threads](https://juarezjunior.medium.com/introduction-to-oracle-jdbc-21c-driver-support-for-virtual-threads-189b918c56f4) 


# How to Run the AI Vector Search Demo
Follow the instructions below to run the code in 
[PipelineVectorDemo.java](src/main/java/com/oracle/dev/jdbc/PipelineVectorDemo.java)

## Create a config.properties file
Examples in this module will read a JDBC URL, username, and password from
`src/main/resources/config.properties`. This command will create the file from a
template:
```shell
cp -i src/main/resources/example-config.properties src/main/resources/config.properties
```
Edit the copy with the configuration of your database.

## Configure the Oracle Cloud Client
The example will request embeddings from the Generative AI service of Oracle
Cloud. Credentials are read from an 
[OCI config file](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/devguidesetupprereq.htm).
Click the link for instructions to create this file.

As of July 2024, the Generative AI service is only available in Chicago and
Frankfurt regions. Check the [Manage Regions](https://cloud.oracle.com/regions) 
page to see if your tenancy is available in either region. If your home region
is not Chicago or Frankfurt, you may need  to add a new profile in your OCI 
config file which uses one of these regions. Here's an example where new 
profiles will inherit all values from the default profile, but override the home
region of Phoenix:
```
[DEFAULT]
user = ocid1.user.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
fingerprint = bb:bb:bb:bb:bb:bb:bb:bb:bb:bb:bb:bb:bb:bb:bb:bb
tenancy = ocid1.tenancy.oc1..cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
region = us-phoenix-1
key_file = /path/to/api-key.pem

[FRANKFURT]
region = eu-frankfurt-1

[CHICAGO]
region = us-chicago-1

```

The requests will need to identify a compartment of your tenancy. Check the 
[Compartments](https://cloud.oracle.com/identity/compartments) page to find the
OCID of your compartment.

The requests will need to identify an embedding model. Check 
[Embedding Playground](https://cloud.oracle.com/ai-service/generative-ai/playground/embed)
page to find the OCID of a model (click the "View model details" button).

The demo code will read the profile name, compartment OCID, and model OCID from
environment variables. These can be set with an `export` command in a bash 
shell:
```shell
export OCI_PROFILE=FRANKFURT
export COMPARTMENT_OCID=ocid1.compartment.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
export MODEL_OCID=ocid1.generativeaimodel.oc1.eu-frankfurt-1.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
```

## Run the code
After creating the config.properties file, and setting environment variables for
OCI, the code can be run with:
```shell
mvn clean compile
mvn dependency:copy-dependencies
java --enable-preview -Doracle.jdbc.disablePipeline=false -cp "target/classes:target/dependency/*" com.oracle.dev.jdbc.PipelineVectorDemo
```
A few notes:
- The code requires JDK 22. Run `java -version` to check your version. The code may also work with future JDK versions, but only if the Structured Concurrency API remains unchanged.
- The `oracle.jdbc.disablePipeline=false` setting is required for Mac OS users. [Find more details about this here](https://github.com/oracle/oracle-r2dbc?tab=readme-ov-file#out-of-band-breaks)
- Pipelining and VECTOR support are introduced in Oracle JDBC 23.4. The ojdbc11 dependency must be of version 23.4 or newer.
