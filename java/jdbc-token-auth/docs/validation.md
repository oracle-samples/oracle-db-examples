# Validation record

## Explicit OCI workload-principal examples: October 8, 2026

- `mvn -B -ntp verify`: 24 tests passed, including seven new selector, scope, URL and expected-session-identity checks for `OciWorkloadPrincipalDemo`.
- The new standalone entry point supports `instance|resource` with `check|jdbc|ucp`. It uses the pinned real provider dependencies and no default/API-key fallback.
- The two deployment recipes are complete but **not yet live-validated on Compute or Data Science**. Offline `check` is not cloud authentication. The previous API-key/operator results below do not validate these workload principals; renewal also remains untested for them.

## Entra and simplified configuration: October 6, 2026

- Local Maven verification passes on Oracle GraalVM JDK 21, Java 17 release target. The suite now includes 17 tests, all 13 shipped profiles, EZConnect+ validation, explicit acquisition-mode conflicts, released provider discovery, and concurrent OCI PoP / Entra bearer token caches. Unit tokens are synthetic and never sent to a database.
- With explicit owner authorization, appended `TokenDemo.Connect` to the existing Entra database application, assigned it only to the existing demo client, and created a dedicated `TOKEN_DEMO` global schema with `CREATE SESSION` only. Existing app roles, DDS settings, external identity-provider configuration, and application data were preserved.
- Live connections used the existing Entra-integrated Oracle database over EZConnect+ TCPS with an mTLS wallet. No database username/password was passed by the token application. Every successful read-only DUAL query returned `SESSION_USER=TOKEN_DEMO`, `AUTHENTICATION_METHOD=TOKEN_GLOBAL`, and the expected client identity.

| Live Entra path | Result |
|---|---|
| Simplified `AZURE_SERVICE_PRINCIPAL` provider | Two JDBC logins; two UCP rounds / eight borrows passed |
| Azure Identity SDK, direct connection builder | Two logins passed |
| Azure Identity SDK, cached supplier | Two JDBC logins; two UCP rounds / eight borrows passed |
| External client-credentials JWT file with `OAUTH` | Two JDBC logins; two UCP rounds / eight borrows passed |

- Each UCP diagnostic round purged all physical connections after workers returned them and verified `available=0 borrowed=0`. Subsequent rounds retained the same data source/token cache and established fresh database sessions. The prior concurrent per-borrow invalidation test intermittently failed with UCP code 45069; removing reuse-count retirement alone did not resolve it. The current implementation uses a documented, quiescent pool purge instead. Do not use SID changes alone as proof: server session IDs can be reused.
- An initial externally acquired JWT lacked the newly assigned role and failed with ORA-01017. A later token included `TokenDemo.Connect` and succeeded. Role assignment is not proof that an already acquired token contains the role; check locally decoded metadata and reacquire after propagation. Never publish a live JWT.
- These are short live authentication tests, **not an expiry-duration refresh test**. Entra managed identity, certificate-based service principal, browser/device-code, and Azure CLI login remain unverified in their target environments. The tested Entra upstream credential was a client secret injected from existing private configuration.
- A live OCI regression also passed with the migrated `OCI_API_KEY` profile: two JDBC logins and two UCP purge rounds / eight borrows, all returning the intended TOKEN_DEMO mapping and TOKEN_GLOBAL. The existing separate OCI demo database/identity was reused; no OCI configuration or grants were changed.

## Earlier OCI validation: October 4, 2026

- Local build and 11 tests pass on Oracle GraalVM JDK 21, Java 17 release target, Maven 3.9.9. The initial GitHub build also passed on JDK 17 and 21.
- Checks cover environment substitution, transport restrictions, token-mode conflicts, all 11 profiles, pool configuration, released provider discovery, and concurrent JDBC token-cache access using a locally signed synthetic token.
- All 11 packaged configuration-only checks pass without cloud credentials.
- Live tests used Oracle AI Database 26ai, server version 23.26.3.3.0, through an mTLS wallet. After explicit owner approval, ADMIN enabled OCI_IAM and created a dedicated TOKEN_DEMO mapping to the tested IAM identity with CREATE SESSION only. Existing password-based schemas were not altered.
- Successful live authentication: OCI CLI file tokens with JDBC and UCP; OCI SDK direct connection builder, cached JDBC supplier, and concurrent UCP; OCI resource provider with UCP physical-connection replacement. Each run reported SESSION_USER=TOKEN_DEMO and AUTHENTICATION_METHOD=TOKEN_GLOBAL. Queries only read DUAL; no application data was modified.
- The first forced-replacement run encountered a pool wait failure. That revision explicitly called ValidConnection.setInvalid() before returning each connection and allowed a bounded 60-second replacement wait; its short provider run passed. This implementation was superseded by the between-round purge described above after later Entra stress tests exposed intermittent failures.
- At that time, refresh across actual token expiration, Entra authentication, OCI workload identities, and interactive/session-token flows were unverified. See the October 6 record above for the subsequent Entra work. Follow the extended live acceptance procedure in troubleshooting.md for expiry and workload validation.

No wallet, database password, private key, cloud account identifier, or live token is included in this repository. Temporary CLI/Entra token files used for validation were removed afterward.
