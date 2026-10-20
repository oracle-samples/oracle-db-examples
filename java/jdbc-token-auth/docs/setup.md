# Database and identity setup

These examples target Autonomous AI Database Serverless. A JDBC release number does not enable identity integration on a database. Other Oracle Database deployments require their own supported server configuration. Use a lab database and an administrator for setup; the Java demo needs only CREATE SESSION and reads DUAL.

OCI IAM and Entra are alternative external identity provider configurations. Use separate lab databases to demonstrate both. The SQL scripts omit forced replacement and stop on errors. They are first-time setup scripts, not repeatable migrations. If TOKEN_DEMO already exists, inspect its mapping rather than dropping it.

## OCI IAM

For complete Compute instance-principal and Data Science resource-principal deployment recipes, including a full Java program, use [OCI workload principals](oci-workload-principals.md).

1. Create or select an IAM user and group, for example TokenDemoUsers; add the user to that group. For non-default identity domains use the domain-qualified names supported by your tenancy.
2. Create a policy scoped to the target database. Replace each placeholder in this example:

   ```text
   Allow group TokenDemoUsers to use autonomous-database-family in compartment DemoCompartment
     where target.id = '<database-ocid>'
   ```

3. As ADMIN in SQLcl, SQL*Plus, or Database Actions, enable OCI IAM and map the user. With SQLcl run `@sql/oci-setup.sql`; Database Actions users should run the SQL statements and replace the prompt variable manually. Enter the exact IAM name; a non-default domain uses `domain/name`. The script creates TOKEN_DEMO and grants CREATE SESSION. A shared group mapping is included as an alternative. Choose one mapping for this demonstration.
4. For local API-key authentication, register an API signing public key with the IAM user and configure the matching private key using `oci setup config`. Keep it outside the repository. An OCI config profile has `user`, `tenancy`, `region`, `fingerprint`, and `key_file` values. The API signing key authenticates the OCI API request; it is different from the per-token proof-of-possession key.
5. Record the compartment and Autonomous Database OCIDs. Set `OCI_DB_SCOPE` to `urn:oracle:db::id::<compartment-ocid>::<database-ocid>`. Token scope, cloud policy, and database mapping are independent requirements.
6. For an instance principal, create an IAM dynamic group whose matching rule contains the intended compute instance. For a resource principal, include the intended supported resource. Grant that dynamic group the scoped database policy and create a shared database mapping with `IAM_GROUP_NAME=<dynamic-group-name>`. Run in the actual workload environment; choosing the profile on a laptop does not create that identity. Do not try to exclusively map an instance/resource principal as an IAM user.

For a session-token profile, first authenticate with `oci session authenticate`, then use the CLI with `--auth security_token --profile <profile>` or the SDK example with `app.oci.authentication=session-token`. A database token refresh cannot rescue an expired upstream login session: renew the login session too. The resource-provider `config-file` method in this release uses API-key configuration; do not assume it reads a session token just because one appears in the file. Cloud Shell and interactive provider profiles demonstrate the other supported user-session paths.

Sources: [enable IAM](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/enable-iam-authentication.html), [policies and dynamic groups](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/iam-create-groups-policies.html), [user mappings](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/iam-create-users.html), [OCI SDK authentication](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdk_authentication_methods.htm).

## Microsoft Entra ID

1. Register the **database resource application** in the Entra tenant. Record its application ID and Application ID URI. Expose a delegated database scope such as `session:scope:connect` for interactive clients. The URI identifies the database resource; it is not the Java client's ID.
2. On that database registration, define the app-role **value** `TokenDemo.Connect` (the display name can differ). Allow Applications for client credentials and Users/Groups for interactive users, according to the intended scenarios.
3. Register the **Java client application** separately. For service-principal authentication, add the database app's Application permission `TokenDemo.Connect` and grant administrator consent. Configure a certificate or create a client secret. `AZURE_CLIENT_ID` identifies this Java client, whereas `ENTRA_DB_APP_ID_URI` is the bare database resource URI used by provider profiles. `ENTRA_DB_SCOPE` is that resource followed by `/.default` for workload SDK/file acquisition.
4. For browser authentication, configure the client as a public/native client and register `http://localhost:8400` as its redirect URI. Give it the delegated database permission and any required consent. Assign the user/group to the database application's role. For device-code authentication enable the appropriate public-client flow. These flows are subject to tenant Conditional Access policy. For v2 interactive tokens, configure the `upn` optional claim as described in Oracle's guide.
5. For managed identity, assign the database app role to the managed identity's service principal; enabling an Azure VM identity alone does not grant database access. Use the identity's client ID for a user-assigned identity. Unset `AZURE_CLIENT_ID` for a system-assigned identity so an unrelated application ID is not selected.
6. As ADMIN on the Entra lab database, run `@sql/entra-setup.sql`. Supply the tenant and **database** registration values. The script enables `AZURE_AD`, maps `AZURE_ROLE=TokenDemo.Connect` to TOKEN_DEMO, and grants CREATE SESSION. The SQL provider identifier remains AZURE_AD even though the product is now called Entra ID.
7. If Entra is already enabled for this resource, preserve its configuration and existing DDS roles. Add only the dedicated role and assignment, inspect whether TOKEN_DEMO already exists, then run just the CREATE USER and GRANT statements if it does not. Do not run the first-time enablement script against an existing integration.
8. For a v1 token, match the registered database Application ID URI. For v2, follow Oracle's audience configuration guidance; the token audience is the application ID. Verify the token version and resource configuration with the administrators rather than substituting a Microsoft Graph scope.

Sources: [registration, roles, consent, token versions, and server setup](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/autonomous-azure-ad-enable.html), [schema mapping](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/autonomous-azure-ad-role-schema-map.html), [managed identity app-role assignment](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/assign-app-role-managed-identity-azure-cli).

## TLS and wallets

Use the TCPS host, port, and service from Database Connection in an EZConnect+ URL:

```text
jdbc:oracle:thin:@tcps://<adb-host>:1522/<service>?connect_timeout=20
```

The demo deliberately accepts a single-host EZConnect+ TCPS URL, not aliases or full descriptors. It permits only numeric connection/retry URL options; keep authentication properties out of URLs. Driver-default server identity matching remains enabled without adding a DN-match URL flag.

For mTLS, extract the wallet to a private directory outside the checkout, copy a profile to an ignored `*.local.properties` file, and add:

```properties
oracle.net.wallet_location=(SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=${ADB_WALLET_DIR})))
```

Set `ADB_WALLET_DIR` to the absolute path. The POM includes Oracle PKI support. If the wallet needs a password, inject `oracle.net.wallet_password=${ADB_WALLET_PASSWORD}` in the local file; never put a literal password there. TLS-only connections do not need a client wallet when the service supports them and the JVM trusts the server CA. The token directory is not a TLS wallet. Server identity matching remains enabled.

## Cleanup

The Java program makes no persistent data changes. Close it to destroy its connection pool. Remove the dedicated demo user's CREATE SESSION grant or drop that dedicated user only after confirming it owns no needed objects. Remove demo-only IAM policies, group membership, app-role assignments and client credentials in their respective consoles. Do not disable a database's identity integration if other users depend on it.
