package demo;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.Properties;
import java.util.regex.Pattern;

/** Loads a sample configuration without ever printing credential values. */
public record Settings(String url, String mode, Properties jdbc, Properties app) {
    private static final Pattern VARIABLE = Pattern.compile("\\$\\{([A-Z][A-Z0-9_]*)}");

    public static Settings load(Path path, Map<String, String> env) throws IOException {
        Properties values = new Properties();
        try (var reader = Files.newBufferedReader(path)) { values.load(reader); }
        for (String key : values.stringPropertyNames()) {
            var matcher = VARIABLE.matcher(values.getProperty(key));
            StringBuilder result = new StringBuilder();
            while (matcher.find()) {
                String value = env.get(matcher.group(1));
                if (value == null || value.isBlank())
                    throw new IllegalArgumentException("Set environment variable " + matcher.group(1));
                matcher.appendReplacement(result, java.util.regex.Matcher.quoteReplacement(value));
            }
            matcher.appendTail(result);
            values.setProperty(key, result.toString());
        }
        String url = required(values, "app.url");
        validateUrl(url);
        String mode = values.getProperty("app.mode", "provider");
        if (!java.util.Set.of("file", "provider", "sdk", "entra-sdk").contains(mode))
            throw new IllegalArgumentException("app.mode must be file, provider, sdk, or entra-sdk");
        Properties jdbc = new Properties();
        for (String key : values.stringPropertyNames()) {
            if (key.startsWith("app.")) continue;
            if (!(key.startsWith("oracle.jdbc.") || key.startsWith("oracle.net.")))
                throw new IllegalArgumentException("Unexpected property: " + key);
            if (java.util.Set.of("oracle.jdbc.user", "oracle.jdbc.password").contains(key))
                throw new IllegalArgumentException("Do not set database credentials for token authentication");
            if (key.startsWith("oracle.jdbc.provider.accessToken") || key.equals("oracle.jdbc.accessToken")
                    || key.equals("oracle.jdbc.passwordAuthentication") || key.startsWith("oracle.net.seps_")
                    || key.equals("oracle.net.tns_admin"))
                throw new IllegalArgumentException("Use only the selected token mechanism and EZConnect+; unsupported property: " + key);
            if (java.util.Set.of("oracle.net.ssl_server_dn_match", "oracle.net.tls_server_dn_match").contains(key)
                    && !java.util.Set.of("true", "yes", "on").contains(values.getProperty(key).toLowerCase(java.util.Locale.ROOT)))
                throw new IllegalArgumentException("TLS server identity verification must remain enabled");
            jdbc.setProperty(key, values.getProperty(key));
        }
        jdbc.setProperty("v$session.program", "devrel-developerhub-java-jdbc-token-auth");
        jdbc.putIfAbsent("oracle.net.CONNECT_TIMEOUT", "15000");
        jdbc.putIfAbsent("oracle.jdbc.ReadTimeout", "30000");
        String tokenAuth = jdbc.getProperty("oracle.jdbc.tokenAuthentication");
        if (mode.equals("provider")) {
            if (!java.util.Set.of("OCI_API_KEY", "OCI_INSTANCE_PRINCIPAL", "OCI_RESOURCE_PRINCIPAL",
                    "OCI_DELEGATION_TOKEN", "OCI_INTERACTIVE", "AZURE_SERVICE_PRINCIPAL",
                    "AZURE_MANAGED_IDENTITY", "AZURE_INTERACTIVE", "AZURE_DEVICE_CODE").contains(tokenAuth == null ? "" : tokenAuth))
                throw new IllegalArgumentException("Set a supported oracle.jdbc.tokenAuthentication method");
            if (tokenAuth.startsWith("OCI_")) {
                required(jdbc, "oracle.jdbc.ociCompartment");
                required(jdbc, "oracle.jdbc.ociDatabase");
            } else required(jdbc, "oracle.jdbc.azureDatabaseApplicationIdUri");
        } else if (!mode.equals("file") && tokenAuth != null) {
            throw new IllegalArgumentException("Use only one token acquisition mechanism");
        } else if (mode.equals("file")) {
            if (!java.util.Set.of("OCI_TOKEN", "OAUTH").contains(tokenAuth == null ? "" : tokenAuth))
                throw new IllegalArgumentException("File mode requires OCI_TOKEN or OAUTH");
            required(jdbc, "oracle.jdbc.tokenLocation");
        }
        if (mode.equals("sdk")) required(values, "app.oci.scope");
        if (mode.equals("entra-sdk")) {
            required(values, "app.entra.scope");
            if (!java.util.Set.of("service-principal", "managed-identity", "interactive", "device-code", "azure-cli")
                    .contains(required(values, "app.entra.authentication")))
                throw new IllegalArgumentException("Unsupported app.entra.authentication");
        }
        return new Settings(url, mode, jdbc, values);
    }

    static void validateUrl(String url) {
        String[] parts = url.split("\\?", -1);
        if (parts.length > 2 || !parts[0].matches("jdbc:oracle:thin:@tcps://[A-Za-z0-9.-]+:[0-9]+/[A-Za-z0-9_.-]+"))
            throw new IllegalArgumentException("Use EZConnect+: jdbc:oracle:thin:@tcps://host:port/service (no credentials, aliases, or descriptors)");
        if (parts.length == 2) {
            var seen = new java.util.HashSet<String>();
            for (String option : parts[1].split("&", -1)) {
                String[] pair = option.split("=", -1);
                String key = pair[0].toLowerCase(java.util.Locale.ROOT);
                if (pair.length != 2 || !java.util.Set.of("connect_timeout", "transport_connect_timeout", "retry_count", "retry_delay").contains(key)
                        || !pair[1].matches("[0-9]+(?:ms|sec|min)?") || !seen.add(key))
                    throw new IllegalArgumentException("Only bounded transport options are accepted in the EZConnect+ URL; keep token settings in properties");
            }
        }
    }

    static String required(Properties values, String key) {
        String value = values.getProperty(key);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Missing property " + key);
        return value;
    }
}
