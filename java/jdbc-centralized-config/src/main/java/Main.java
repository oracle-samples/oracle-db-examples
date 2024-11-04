import database.DatabaseConfig;
import database.DatabasePoolConfig;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class Main {

    static DatabaseConfig dbConfig;

    static class Provider {
        static final String OCI_OBJECT_STORE_CONFIG = "jdbc:oracle:thin:@config-ociobject://<url-path>";
        static final String BUILT_IN_FILE_CONFIG    = "jdbc:oracle:thin:@config-file://<path-to-json-file>";
        static final String AZURE_APP_CONFIG        = "jdbc:oracle:thin:@config-azure://<appconfig-name>";
        static final String OCI_VAULT_CONFIG        = "jdbc:oracle:thin:@config-ocivault://<vault-secret-ocid>";
        static final String NORMAL_CONFIG           = "jdbc:oracle:thin:@<connect-string>";
    }

    public static void main(String[] args) {
        System.setProperty("ORACLE_URL", Provider.BUILT_IN_FILE_CONFIG);
        dbConfig = DatabaseConfig.get();
        runConnectionTest();

    }

    // Test method
    private static void runConnectionTest() {



        boolean success = false;
        try (Connection c = dbConfig.getConnection();
             PreparedStatement stmt = c.prepareStatement("select 'true' from dual");
             ResultSet rs = stmt.executeQuery()){

            // Boolean Datatype is a 23ai feature
            if (rs.next()) success = rs.getBoolean(1);

        } catch (SQLException e) {
            e.printStackTrace();
        }

        System.out.println("Success: " + success);
    }
}