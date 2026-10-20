# Troubleshooting and verification boundaries

| Symptom | Check |
|---|---|
| Configuration check fails | Set each named environment variable; use an EZConnect+ TCPS URL; choose one acquisition method. The check does not validate cloud credentials. |
| Missing provider / class not found | Run `mvn clean verify`; keep all `target/lib` JARs. The runtime uses the original JAR service descriptors. Do not shade them without service-resource merging. |
| ORA-01017 | Token audience/scope, external provider, mapping, cloud permission, expired token, and credentials. This code alone does not establish which is wrong. A password connection failing with this error has not tested tokens. |
| ORA-01045 | Grant CREATE SESSION to the mapped schema. |
| ORA-20004 during setup | Another identity provider is already configured. Use the corresponding lab database; these scripts do not force replacement. |
| Timeout / ORA-125xx | DNS, routing, ACLs, private endpoint access, TCPS port, and service name. |
| TLS / wallet failure | Correct database wallet, CA trust, wallet path and password if needed; preserve server name checks. |
| OCI authorization failure | Correct API profile or actual workload identity; policy target OCID, group/dynamic group, scope and database mapping must agree. |
| Entra invalid scope / unauthorized client | Use database resource scope rather than Graph; distinguish client and resource IDs, app roles, consent, and tenant policy. |
| Initial connection works; later physical connections fail | Token refresh, upstream identity expiry, IAM endpoint reachability, or CLI file refresh. Existing pooled sessions can hide the problem. |

The CLI emits exception type and Oracle numeric code, not full exception payloads. Inspect detailed diagnostics only in a controlled environment: SDK logging may include identity/request information. Do not paste live tokens into online decoders. Identity query output contains principal names; redact them before sharing logs.

## Repeatable live acceptance checks

1. `mvn clean verify` runs offline-with-respect-to-cloud unit tests. It may download Maven dependencies. `./run.sh --help` verifies the packaged entry point.
2. `./run.sh config/oci-config-file.properties check` validates configuration without calling OCI or the database. This is not a live authentication test.
3. Run `jdbc`, then `ucp`, with a configured identity. Confirm the printed schema is the intended TOKEN_DEMO mapping. The exact AUTHENTICATION_METHOD text depends on the server.
4. Run `ucp-fresh 75 60` to request four borrows per round over roughly 74 minutes. Diagnostic mode purges only after all four tasks return their connections and checks that the pool is empty, retaining the same data source/token cache. It allows 60 seconds for replacement connections. Printed SIDs are useful diagnostics but can be recycled by the server. This setting is diagnostic, not a production tuning recommendation. Choose a duration beyond the actual token lifetime, which can differ between issuers.
5. For file mode, ensure the external producer refreshes the OCI token/PoP-key pair coherently, or the single Entra JWT file, before expiry. Without refresh, a fresh physical connection after expiry should fail. Provider and SDK modes own token acquisition/cache refresh, but upstream credentials must remain valid.
6. Repeat for each cloud/identity type you intend to deploy. A passing OCI API-key run does not validate instance principal, resource principal, or Entra.

The repository's automated tests do not provision or contact OCI, Entra or an Oracle Database. Published test results must distinguish those tests from live authentication runs.
