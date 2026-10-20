# Complete OCI workload-principal examples

Two deployment recipes use the same complete [Java program](../src/main/java/demo/OciWorkloadPrincipalDemo.java): an OCI Compute **instance principal** and an OCI Data Science notebook **resource principal**. Both support JDBC and UCP, use TCPS EZConnect+, and query only session identity. Neither selects `OCI_DEFAULT`, reads an API-key profile, accepts a database password, or falls back to another principal.

**Validation boundary:** the program and configuration tests run with `mvn verify`. `check` is offline. These two runtime recipes have not yet been live-validated in this repository; a passing operator API-key test is not a workload-principal result. A successful run must print `PASS` after checking the expected schema and `TOKEN_GLOBAL`. One connection does not prove token renewal.

## Prerequisites common to both recipes

1. Use a dedicated IAM-enabled Autonomous AI Database with a TLS connection endpoint reachable from the runtime. Record its host, port, service, compartment OCID and database OCID. Do not reuse an Entra-configured database or change a shared database's identity provider for this example.
2. If IAM is not enabled on this dedicated database, its administrator runs:

   ```sql
   BEGIN
     DBMS_CLOUD_ADMIN.ENABLE_EXTERNAL_AUTHENTICATION(type => 'OCI_IAM');
   END;
   /
   ```

3. Use the service's documented **dynamic-group/shared-schema mapping** below. Replace every placeholder before running the SQL or creating policies. The identity domain prefix is required for a non-default domain. Create each group/policy/schema once; do not overwrite an existing mapping.
4. Install Java 17+ and Maven in each target runtime, then build from the public source:

   ```sh
   git clone https://github.com/paulparkinson/oracle-db-examples.git
   cd oracle-db-examples/java/jdbc-token-auth
   mvn -B -ntp verify
   export ADB_JDBC_URL='jdbc:oracle:thin:@tcps://<host>:<port>/<service>'
   export OCI_COMPARTMENT_ID='<database-compartment-ocid>'
   export OCI_DATABASE_ID='<autonomous-database-ocid>'
   ```

   The existing POM supplies JDBC/UCP `23.26.3.0.0`, OCI provider `1.1.0`, and OCI SDK `3.86.2`. Keep the original JARs in `target/lib`; do not flatten ServiceLoader entries. Use the database's TLS endpoint and a trusted certificate chain. This recipe needs no client-certificate wallet or `tnsnames.ora`. If your database requires mTLS, configure its wallet separately rather than disabling TLS checks. No `dn_match` URL parameter is needed for this EZConnect+ recipe.

## 1. OCI_INSTANCE_PRINCIPAL — run on OCI Compute

1. Choose a dedicated Compute VM that can reach the database and OCI IAM endpoints. Create dynamic group `JdbcInstanceDemo` with an exact-instance matching rule:

   ```text
   instance.id = '<compute-instance-ocid>'
   ```

2. Create a database-scoped IAM policy (substitute the identity-domain-qualified dynamic group name when needed):

   ```text
   Allow dynamic-group JdbcInstanceDemo to use autonomous-database-family in compartment id <database-compartment-ocid> where target.id = '<autonomous-database-ocid>'
   ```

   `use autonomous-database-family` is the Autonomous service's documented token policy, not permission to create/drop database schemas. For Base Database Service, use its separate `database-connections` policy and `target.database.id` condition; do not copy an Autonomous policy unchanged.

3. As the database administrator, create the dedicated global schema, with no application privileges:

   ```sql
   CREATE USER TOKEN_INSTANCE_DEMO
     IDENTIFIED GLOBALLY AS 'IAM_GROUP_NAME=JdbcInstanceDemo';
   GRANT CREATE SESSION TO TOKEN_INSTANCE_DEMO;
   ```

4. In the VM shell, build and export the three common variables above, then run:

   ```sh
   export EXPECTED_DB_USER=TOKEN_INSTANCE_DEMO
   java -cp 'target/classes:target/lib/*' demo.OciWorkloadPrincipalDemo instance check
   java -cp 'target/classes:target/lib/*' demo.OciWorkloadPrincipalDemo instance jdbc
   java -cp 'target/classes:target/lib/*' demo.OciWorkloadPrincipalDemo instance ucp
   ```

The program sets `oracle.jdbc.tokenAuthentication=OCI_INSTANCE_PRINCIPAL`, plus `oracle.jdbc.ociCompartment` and `oracle.jdbc.ociDatabase`. The provider obtains the VM's identity through OCI instance metadata and requests a database-scoped token. No `oracle.jdbc.provider.accessToken`, API key, OCI CLI login, username, or password is supplied. Protect access to instance metadata: processes on this VM share its principal.

## 2. OCI_RESOURCE_PRINCIPAL — run in an OCI Data Science notebook

1. Create or select a dedicated notebook session with database/IAM network access. Open its JupyterLab **terminal**; Java runs there, not on your laptop. Create dynamic group `JdbcResourceDemo` with an exact-resource matching rule:

   ```text
   ALL {resource.type = 'datasciencenotebooksession', resource.id = '<notebook-session-ocid>'}
   ```

2. Create its separately scoped policy:

   ```text
   Allow dynamic-group JdbcResourceDemo to use autonomous-database-family in compartment id <database-compartment-ocid> where target.id = '<autonomous-database-ocid>'
   ```

3. As the database administrator, create its schema:

   ```sql
   CREATE USER TOKEN_RESOURCE_DEMO
     IDENTIFIED GLOBALLY AS 'IAM_GROUP_NAME=JdbcResourceDemo';
   GRANT CREATE SESSION TO TOKEN_RESOURCE_DEMO;
   ```

4. In the notebook terminal, build and export the three common variables above, then run:

   ```sh
   export EXPECTED_DB_USER=TOKEN_RESOURCE_DEMO
   java -cp 'target/classes:target/lib/*' demo.OciWorkloadPrincipalDemo resource check
   java -cp 'target/classes:target/lib/*' demo.OciWorkloadPrincipalDemo resource jdbc
   java -cp 'target/classes:target/lib/*' demo.OciWorkloadPrincipalDemo resource ucp
   ```

The program sets `oracle.jdbc.tokenAuthentication=OCI_RESOURCE_PRINCIPAL` with the same two scope properties. The OCI SDK reads the runtime's resource-principal environment/material; leave those runtime-managed values intact. Do not print, copy, hard-code, or manufacture `OCI_RESOURCE_PRINCIPAL_*` credentials. Data Science caches its resource-principal token for 15 minutes, so policy changes may not appear immediately. Dynamic-group changes also need propagation time.

**This is not an OKE workload-identity example.** An OKE service-account token or a GKE identity is not automatically the generic OCI resource-principal credential expected by this provider. Those paths need separate integration and database acceptance tests.

## What the complete Java program checks

- Explicit selector and database scope; no default credential chain or fallback.
- TCPS EZConnect+ URL validation; 15-second connection timeout and 30-second JDBC read timeout. These are not an overall deadline for cloud SDK token acquisition.
- `PreparedStatement` executes only `SYS_CONTEXT` against `DUAL`, with a 20-second query timeout.
- Expected `SESSION_USER` and `AUTHENTICATION_METHOD=TOKEN_GLOBAL`; a mismatched identity fails the run.
- UCP has at most two connections, a 20-second borrow wait, validation on borrow, and pool cleanup. The short run proves neither concurrency nor token renewal; use the existing `ucp-fresh` harness for an approved longer renewal test.
- No tokens, keys, credentials, or raw exception payloads in output.

## Test and remove a dedicated example safely

1. Capture only the selector, UTC test time, exit code and identity-check outcome. Token issuance alone is insufficient.
2. For a negative control, use a separate otherwise-identical runtime excluded from the dynamic group; it must fail. Do not remove shared production policies to test this.
3. To test renewal after initial success, use the matching existing profile with `./run.sh config/oci-instance-principal.properties ucp-fresh 38 120` (or `oci-resource-principal.properties`). Check fresh physical connections beyond the issued token lifetime; never infer renewal from reusing one session.
4. When finished, remove only the example's dedicated policy and group, drop the two unused example schemas without `CASCADE`, and terminate/deactivate its dedicated runtime. Leave shared resources and mappings unchanged.

## References

- [JDBC authentication selectors and scope properties](https://docs.oracle.com/en/database/oracle/oracle-database/26/jajdb/oracle/jdbc/OracleConnection.html)
- [OCI JDBC provider](https://github.com/oracle/ojdbc-extensions/tree/main/ojdbc-provider-oci)
- [Autonomous IAM policies and dynamic-group mapping](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/iam-create-groups-policies.html)
- [Autonomous global schema mappings](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/iam-create-users.html)
- [Data Science resource-principal runtime](https://docs.oracle.com/en-us/iaas/Content/data-science/using/use-notebook-sessions.htm)
- [Base Database IAM configuration](https://docs.oracle.com/en/cloud/paas/base-database/iam/)

The general Database Security Guide also documents exclusive principal-OCID mappings. Autonomous's service-specific page instead requires dynamic-group shared mappings for instance/resource principals; this recipe follows the service-specific path rather than claiming those alternatives are interchangeable.
