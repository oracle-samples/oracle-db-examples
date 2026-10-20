package demo;

import com.oracle.bmc.auth.AbstractAuthenticationDetailsProvider;
import com.oracle.bmc.auth.ConfigFileAuthenticationDetailsProvider;
import com.oracle.bmc.auth.InstancePrincipalsAuthenticationDetailsProvider;
import com.oracle.bmc.auth.ResourcePrincipalAuthenticationDetailsProvider;
import com.oracle.bmc.auth.SessionTokenAuthenticationDetailsProvider;
import com.oracle.bmc.identitydataplane.DataplaneClient;
import com.oracle.bmc.identitydataplane.model.GenerateScopedAccessTokenDetails;
import com.oracle.bmc.identitydataplane.requests.GenerateScopedAccessTokenRequest;
import oracle.jdbc.AccessToken;
import java.security.KeyPairGenerator;
import java.util.Base64;
import java.util.Properties;
import java.util.function.Supplier;

/** Application-owned SDK acquisition: the PoP key never leaves memory. */
public final class OciTokens {
    private OciTokens() {}

    public static Supplier<? extends AccessToken> cached(Properties settings) {
        return AccessToken.createJsonWebTokenCache(() -> request(settings));
    }

    public static AccessToken request(Properties settings) {
        try {
            String profile = settings.getProperty("app.oci.profile", "DEFAULT");
            String file = settings.getProperty("app.oci.configFile",
                    System.getProperty("user.home") + "/.oci/config");
            AbstractAuthenticationDetailsProvider identity = switch (
                    settings.getProperty("app.oci.authentication", "config-file")) {
                case "config-file" -> new ConfigFileAuthenticationDetailsProvider(file, profile);
                case "session-token" -> new SessionTokenAuthenticationDetailsProvider(file, profile);
                case "instance-principal" -> InstancePrincipalsAuthenticationDetailsProvider.builder().build();
                case "resource-principal" -> ResourcePrincipalAuthenticationDetailsProvider.builder().build();
                default -> throw new IllegalArgumentException("Unsupported app.oci.authentication");
            };
            try {
                var generator = KeyPairGenerator.getInstance("RSA");
                generator.initialize(2048);
                var pair = generator.generateKeyPair();
                var details = GenerateScopedAccessTokenDetails.builder()
                        .scope(Settings.required(settings, "app.oci.scope"))
                        .publicKey(Base64.getEncoder().encodeToString(pair.getPublic().getEncoded()))
                        .build();
                try (var client = DataplaneClient.builder().build(identity)) {
                    String jwt = client.generateScopedAccessToken(GenerateScopedAccessTokenRequest.builder()
                            .generateScopedAccessTokenDetails(details).build()).getSecurityToken().getToken();
                    return AccessToken.createJsonWebToken(jwt.toCharArray(), pair.getPrivate());
                }
            } finally {
                if (identity instanceof SessionTokenAuthenticationDetailsProvider session) session.close();
            }
        } catch (Exception failure) {
            // SDK exception messages can contain request details; the CLI prints only the type.
            throw new IllegalStateException("OCI token acquisition failed", failure);
        }
    }
}
