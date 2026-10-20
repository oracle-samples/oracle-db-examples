package demo;

import com.azure.core.credential.TokenCredential;
import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.*;
import oracle.jdbc.AccessToken;
import java.time.Duration;
import java.util.Properties;
import java.util.function.Supplier;

/** Explicit Azure Identity acquisition; no database password or OCI PoP key. */
public final class EntraTokens {
    private EntraTokens() {}

    public static Supplier<? extends AccessToken> cached(Properties settings) {
        return AccessToken.createJsonWebTokenCache(supplier(settings));
    }

    static Supplier<AccessToken> supplier(Properties settings) {
        TokenCredential credential = switch (Settings.required(settings, "app.entra.authentication")) {
            // Azure Identity reads AZURE_TENANT_ID, AZURE_CLIENT_ID and secret/certificate from the environment.
            case "service-principal" -> new EnvironmentCredentialBuilder().build();
            case "managed-identity" -> {
                var builder = new ManagedIdentityCredentialBuilder();
                String clientId = System.getenv("AZURE_CLIENT_ID");
                if (clientId != null && !clientId.isBlank()) builder.clientId(clientId);
                yield builder.build();
            }
            case "interactive" -> new InteractiveBrowserCredentialBuilder()
                    .tenantId(Settings.required(settings, "app.entra.tenantId"))
                    .clientId(Settings.required(settings, "app.entra.clientId"))
                    .redirectUrl(settings.getProperty("app.entra.redirectUri", "http://localhost:8400"))
                    .build();
            case "device-code" -> new DeviceCodeCredentialBuilder()
                    .tenantId(Settings.required(settings, "app.entra.tenantId"))
                    .clientId(Settings.required(settings, "app.entra.clientId"))
                    .challengeConsumer(c -> System.out.println(c.getMessage())).build();
            case "azure-cli" -> new AzureCliCredentialBuilder()
                    .tenantId(Settings.required(settings, "app.entra.tenantId")).build();
            default -> throw new IllegalArgumentException("Unsupported app.entra.authentication");
        };
        String scope = Settings.required(settings, "app.entra.scope");
        return () -> {
            try {
                var token = credential.getToken(new TokenRequestContext().addScopes(scope))
                        .block(Duration.ofSeconds(120));
                if (token == null) throw new IllegalStateException("No Entra token returned");
                return AccessToken.createJsonWebToken(token.getToken().toCharArray());
            } catch (Exception failure) {
                throw new IllegalStateException("Entra token acquisition failed", failure);
            }
        };
    }
}
