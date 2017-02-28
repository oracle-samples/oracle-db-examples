/*
 * -- DISCLAIMER:
   -- This script is provided for educational purposes only. It is
   -- NOT supported by Oracle World Wide Technical Support.
   -- The script has been tested and appears to work as intended.
   -- You should always run new scripts initially
   -- on a test instance.
 */
package mypackage;

import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Date;
import java.util.HashMap;
import oracle.jdbc.OracleConnection;

public class InsertExamples {

    private String dbURL = "jdbc:oracle:thin:adhoc/adhoc@myusmachine:7796:npbr";
    private OracleConnection connection;
    private String driver = "oracle.jdbc.OracleDriver";
    private long startTime = 0;
    private final int rowCount = 10;
    private HashMap<String,Integer> doNothingStats = new HashMap<>();

    private void timeInit() {
        startTime = (new Date()).getTime();
    }

    private void message(String message) {
        System.out.println(message);
    }

    private void message2(String message) {
        System.out.println("    " + message);
    }

    private String randomString(int length) {
        StringBuilder s = new StringBuilder();
        while (s.length() < length) {
            s.append("-" + Math.random());
        }
        return s.substring(0, length);
    }

    private void timeReport() {
        long runTime = (new Date()).getTime() - startTime;
        message("");
        message("Elapsed time = " + runTime + " miliseconds");
    }

    public void reportDB() throws Exception {
        reportDB(false);
    }

    public void reportDB(boolean keep) throws Exception {
        if (keep) {
            this.doNothingStats.clear();
        }
        PreparedStatement s =
            connection.prepareStatement("select name,value from v$mystat m, v$statname n where m.statistic# = n.statistic# " +
                                        "and name in ('parse count (hard)','parse count (total)','user commits','execute count'," +
                                        "'bytes received via SQL*Net from client','bytes sent via SQL*Net to client'," +
                                        "'SQL*Net roundtrips to/from client') " + " order by name");
        ResultSet rs = s.executeQuery();
        message("");
        message("SELECT name,value FROM v$mystat, v$statname...");
        message("");
        if (!keep) {
            message(String.format("%1$61s", " ") + "+ baseline comparison");
        }
        while (rs.next()) {
            String name = rs.getString(1);
            int value = rs.getInt(2);
            String fixedName = String.format("%1$45s", name);
            String fixedValue = String.format("%1$10s", " " + value);
            if (keep) {
                message(fixedName + " " + fixedValue);
                this.doNothingStats.put(name, new Integer(value));
            } else {
                int delta = value - (int) this.doNothingStats.get(name);
                message(fixedName + "  " + fixedValue + "    + " + delta);
            }
        }
        rs.close();
        message("");
    }

    public void open() throws Exception {
        message("Connecting...");

        Class.forName(driver);

        connection = (OracleConnection) DriverManager.getConnection(dbURL);

        connection.setAutoCommit(false);

        message("Connected");
    }

    public void close() throws Exception {
        connection.close();
    }

    public void doNothing() throws Exception {
        message2("Do nothing to get baseline statistics...");
        timeInit();
        timeReport();
    }

    public void fixedValuesAutoCommit() throws Exception {
        message2("Insert fixed values into table using literals, parsing once, auto committing every row.");
        message2("PARSE INSERT INTO table VALUES ('XXXX')");
        message2("LOOP");
        message2("   EXECUTE INSERT AND COMMIT");
        message2("END LOOP");
        timeInit();
        PreparedStatement s =
            connection.prepareStatement("insert into ins values (10,'XXXXXXXXXXXXXXXXXXXX','YYYYYYYYYYYYYYYYYYYY')");

        connection.setAutoCommit(true);

        for (int i = 0; i < rowCount; i++) {
            s.execute();
        }
        s.close();
        timeReport();

        connection.setAutoCommit(false);
    }

    public void fixedValuesCommitAfterEachInsert() throws Exception {
        message2("Insert fixed values into table using literals, parsing once, committing every row manually.");
        message2("PARSE INSERT INTO table VALUES ('XXXX')");
        message2("LOOP");
        message2("   EXECUTE INSERT");
        message2("   COMMIT");
        message2("END LOOP");
        timeInit();
        PreparedStatement s =
            connection.prepareStatement("insert into ins values (10,'XXXXXXXXXXXXXXXXXXXX','YYYYYYYYYYYYYYYYYYYY')");

        connection.setAutoCommit(false);

        for (int i = 0; i < rowCount; i++) {
            s.execute();
            connection.commit();
        }
        s.close();
        timeReport();
    }

    public void fixedValuesCommitAtEnd() throws Exception {
        message2("Insert fixed values into table using literals, parsing once, committing once all rows have been inserted.");
        message2("PARSE INSERT INTO table VALUES ('XXXX')");
        message2("LOOP");
        message2("   EXECUTE INSERT");
        message2("END LOOP");
        message2("COMMIT");
        timeInit();
        PreparedStatement s =
            connection.prepareStatement("insert into ins values (10,'XXXXXXXXXXXXXXXXXXXX','YYYYYYYYYYYYYYYYYYYY')");

        connection.setAutoCommit(false);

        for (int i = 0; i < rowCount; i++) {
            s.execute();
        }
        s.close();
        connection.commit();
        timeReport();
    }

    public void fixedValuesCommitAtEndSoftParse() throws Exception {
        message2("Insert fixed values into table using literals, parsing before each execute, committing once all rows have been inserted.");
        message2("LOOP");
        message2("   PARSE INSERT INTO table VALUES ('XXXX')");
        message2("   EXECUTE INSERT");
        message2("END LOOP");
        message2("COMMIT");
        timeInit();

        connection.setAutoCommit(false);

        for (int i = 0; i < rowCount; i++) {
            PreparedStatement s =
                connection.prepareStatement("insert into ins values (10,'XXXXXXXXXXXXXXXXXXXX','YYYYYYYYYYYYYYYYYYYY')");
            s.execute();
            s.close();
        }

        connection.commit();
        timeReport();
    }

    public void variableValuesCommitAtEndHardParse() throws Exception {
        message2("Insert different values into table using literals, parsing before each execute, committing once all rows have been inserted.");
        message2("LOOP");
        message2("   STRING_VALUE = RANDOM_STRING()");
        message2("   PARSE INSERT INTO table VALUES (' || STRING_VALUE || ')");
        message2("   EXECUTE INSERT");
        message2("END LOOP");
        message2("COMMIT");
        timeInit();

        connection.setAutoCommit(false);

        for (int i = 0; i < rowCount; i++) {
            String s1 = randomString(20);
            String s2 = randomString(20);
            PreparedStatement s = connection.prepareStatement("insert into ins values (10,'" + s1 + "','" + s2 + "')");
            s.execute();
            s.close();
        }

        connection.commit();
        timeReport();
    }

    public void variableValuesCommitAtEndSoftParse() throws Exception {
        message2("Insert different values into table using bind variables (parameters), parsing before each execute, committing once all rows have been inserted.");
        message2("LOOP");
        message2("   STRING_VALUE = RANDOM_STRING()");
        message2("   PARSE INSERT INTO table VALUES (?)");
        message2("   SET PARAMETER = STRING_VALUE");
        message2("   EXECUTE INSERT");
        message2("END LOOP");
        message2("COMMIT");
        timeInit();

        connection.setAutoCommit(false);

        for (int i = 0; i < rowCount; i++) {
            String s1 = randomString(20);
            String s2 = randomString(20);
            PreparedStatement s = connection.prepareStatement("insert into ins values (10,?,?)");
            /*
             Remember to be mindful of data types
             */
            s.setString(1, s1);
            s.setString(2, s2);
            s.execute();
            s.close();
        }

        connection.commit();
        timeReport();
    }


    public void variableValuesCommitAtEndStatementCache() throws Exception {
        message2("Insert different values into table using bind variables (parameters), parsing before each execute but with statement cache, committing once all rows have been inserted.");
        message2("LOOP");
        message2("   STRING_VALUE = RANDOM_STRING()");
        message2("   PARSE INSERT INTO table VALUES (?)");
        message2("   SET PARAMETER = STRING_VALUE");
        message2("   EXECUTE INSERT");
        message2("END LOOP");
        message2("COMMIT");
        timeInit();

        connection.setAutoCommit(false);
        connection.setImplicitCachingEnabled(true);
        connection.setStatementCacheSize(100);

        for (int i = 0; i < rowCount; i++) {
            String s1 = randomString(20);
            String s2 = randomString(20);
            PreparedStatement s = connection.prepareStatement("insert into ins values (10,?,?)");
            /*
             Remember to be mindful of data types
             */
            s.setString(1, s1);
            s.setString(2, s2);
            s.execute();
            s.close();
        }
        connection.setImplicitCachingEnabled(false);
        connection.commit();
        timeReport();
    }

    public void variableValuesCommitAtEndParseOnce() throws Exception {
        message2("Insert different values into table using bind variables (parameters), parsing once, committing once all rows have been inserted.");
        message2("PARSE INSERT INTO table VALUES (?)");
        message2("LOOP");
        message2("   STRING_VALUE = RANDOM_STRING()");
        message2("   SET PARAMETER = STRING_VALUE");
        message2("   EXECUTE INSERT");
        message2("END LOOP");
        message2("COMMIT");
        timeInit();

        connection.setAutoCommit(false);
        PreparedStatement s = connection.prepareStatement("insert into ins values (10,?,?)");

        for (int i = 0; i < rowCount; i++) {
            String s1 = randomString(20);
            String s2 = randomString(20);
            /*
             Remember to be mindful of data types
             */
            s.setString(1, s1);
            s.setString(2, s2);
            s.execute();
        }

        s.close();
        connection.commit();
        timeReport();
    }

    public void variableValuesCommitInBatchParseOnceAndBatch(int batchInsertSize,
                                                             int batchCommitSize) throws Exception {
        message2("Insert different values into table using bind variables (parameters), parsing once, inserting rows in batches of " +
                 batchInsertSize + ", committing in batches of " + batchCommitSize + ".");
        message2("PARSE INSERT INTO table VALUES (?)");
        message2("LOOP");
        message2("   LOOP BATCH SIZE");
        message2("      STRING_VALUE = RANDOM_STRING()");
        message2("      SET PARAMETER[N] = STRING_VALUE");
        message2("   END LOOP");
        message2("   EXECUTE BATCH INSERT N");
        message2("   COMMIT EVENT Mth ROW");
        message2("END LOOP");
        timeInit();

        /* You'll get the most significant benefits setting batchInsertSize to
         * something between 10 and 100. Beyond that, you may see diminishing returns
         * especially for local clients and fast networks. Setting it to 1000's is
         * usually not appropriate.
         * 
         * The value of batchCommitSize can really be anything! If you encounter a 
         * failure and can pick up where you left off, you may set it to something like
         * 10000 or a 1000000 perhaps. If you need to insert a large batch on an
         * all or nothing basis, then you may choose to commit once, when all of the
         * rows have been inserted
         * /

        connection.setAutoCommit(false);
        /*
        Caching is not required in this example, but it is useful in more general examples.
        */
        connection.setImplicitCachingEnabled(true);
        connection.setStatementCacheSize(100);
        PreparedStatement s = connection.prepareStatement("insert into ins values (10,?,?)");

        for (int rowNum = 1; rowNum <= rowCount; rowNum++) {
            String s1 = randomString(20);
            String s2 = randomString(20);
            s.setString(1, s1);
            s.setString(2, s2);
            if (0 == rowNum % batchInsertSize || rowNum == rowCount) {
                s.addBatch();
                s.executeBatch();
            } else {
                s.addBatch();
            }
            if (0 == rowNum % batchCommitSize) {
                // If there is no requirement to roll ALL inserts if
                // there is a failure, then it might be appropriate to
                // commit batches of rows to reduce the amount of UNDO
                // the database needs to retain.
                connection.commit();
            }
        }

        s.close();
        connection.setImplicitCachingEnabled(false);
        connection.commit();
        timeReport();
    }

    public static void main(String[] args) throws Exception {
        InsertExamples ex = new InsertExamples();

        ex.message("****                                                                   ****");
        ex.message("****                                                                   ****");
        ex.message("**** Always run tests multiple times to allow the database statistics  ****");
        ex.message("**** reported here to settle to nominal values.                        ****");
        ex.message("****                                                                   ****");
        ex.message("**** Remember: elapsed times can mislead                               ****");
        ex.message("****         : Focus on reducing parse counts, executions, rountrips   ****");
        ex.message("****         : and transaction rates                                   ****");
        ex.message("****                                                                   ****");
        ex.message("****                                                                   ****");
        ex.message("****           Inserting "+ ex.rowCount + " rows per test");
        ex.message("****                                                                   ****");
        
        ex.open();
        ex.doNothing();
        ex.reportDB(true);
        ex.close();

        /*
         Auto Commit is usually something that you will not
         want to use because commits required redo log entries
         to be committed to storage, but if you must commit every insert, then
         auto commit will reduce network roundtrips.
         The higher the latency in the network, the greater the difference in
         elapsed time between these two examples.
         */
        ex.open();
        ex.fixedValuesCommitAfterEachInsert();
        ex.reportDB();
        ex.close();

        ex.open();
        ex.fixedValuesAutoCommit();
        ex.reportDB();
        ex.close();

        /*
         All rows are inserted and then committed at end.
         You might be forgiven for thinking that commiting once at the
         end of the batch of inserts gives you no benefit. The elapsed time
         might be about the same as the previous example.
         However, elapsed time is DECEPTIVE - remember that you might need to
         scale out using multiple DB connections or the database may be
         busy committing other workloads frequently. In this case,
         committing less frequently significantly improves scalability.
         */
        ex.open();
        ex.fixedValuesCommitAtEnd();
        ex.reportDB();
        ex.close();

        /*
         Here, the INSERT statement is repeatedly re-parsed.
         Elapsed time will not be affected significantly, but re-parsing
         should be avoided where possible. The parses are not "hard", so
         this is not a significant issue yet.
         */
        ex.open();
        ex.fixedValuesCommitAtEndSoftParse();
        ex.reportDB();
        ex.close();

        /*
         This generates a lot of hard parses. Again, this won't affect
         elapsed time significantly for a simple test, but it will
         compromise load scalability significantly.
         */
        ex.open();
        ex.variableValuesCommitAtEndHardParse();
        ex.reportDB();
        ex.close();

        /*
         Variable values inserted using bind variables (parameters)
         No hard parsing any more. Just soft parsing (or perhaps one hard
         when it's executed the first time).
         */
        ex.open();
        ex.variableValuesCommitAtEndSoftParse();
        ex.reportDB();
        ex.close();

        /*
         * The Java keeps closing and re-parsing but the statement cache holds
         * cursors open even if they are closed. This will avoid the
         * need for the database to re-parse the SQL statement.
         * This is reflected in the database statistics:
         * "parse count (total)" will be 1 even though
         * "Prepare" is called multiple times.
         * Remember that an open cursor uses memory on the server,
         * so some care is required when setting the size of the cache if
         * there are likely to be large numbers of connections.
         */
        ex.open();
        ex.variableValuesCommitAtEndStatementCache();
        ex.reportDB();
        ex.close();
        /*
         Variable values being inserted using bind variables (parameters)
         Parsing once only.
         */
        ex.open();
        ex.variableValuesCommitAtEndParseOnce();
        ex.reportDB();
        ex.close();

        /*
         Variable values being inserted using bind variables (parameters)
         Parsing once only.
         Executing in batches to reduce network trountrips and execution rate.
         This is a very scalable solution.
         */
        ex.open();
        ex.variableValuesCommitInBatchParseOnceAndBatch(50, 100000);
        ex.reportDB();
        ex.close();
    }
}
