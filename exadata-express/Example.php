<?php

/*----------------------------------------------------------------------
  Example.php

  Demonstrate how to perform a database insert and query with PHP
  in Oracle Database Cloud services such as Exadata Express,
  Autonomous Transaction Processing, Autonomous Data Warehouse, and
  others.

  Before running this script:
  - Install PHP and the OCI8 extension
  - Install Oracle Instant Client
  - Download and install the cloud service wallet
  - Modify the oci_connect() call below to use the credentials for your database.
  See your cloud service's documentation for details.

  ----------------------------------------------------------------------*/

// Uncomment for testing
// error_reporting(E_ALL);  // In PHP 5.3 use E_ALL|E_STRICT
// ini_set('display_errors', 'On');

// Connect

$c = oci_connect("username", "password", "connect_string");
if (!$c) {
    $m = oci_error();
    trigger_error("Could not connect to database: ". $m["message"], E_USER_ERROR);
}

// Create a table

$stmtarray = array(
    "BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE mycloudtab';
         EXCEPTION
         WHEN OTHERS THEN
           IF SQLCODE NOT IN (-00942) THEN
             RAISE;
           END IF;
       END;",

    "CREATE TABLE mycloudtab (id NUMBER, data VARCHAR2(20))"
);

foreach ($stmtarray as $stmt) {
    $s = oci_parse($c, $stmt);
    if (!$s) {
        $m = oci_error($c);
        trigger_error("Could not parse statement: ". $m["message"], E_USER_ERROR);
    }
    $r = oci_execute($s);
    if (!$r) {
        $m = oci_error($s);
        trigger_error("Could not execute statement: ". $m["message"], E_USER_ERROR);
    }
}

// Insert some data

$data = [ [101, "Alpha" ], [102, "Beta" ], [103, "Gamma" ] ];

$s = oci_parse($c, "INSERT INTO mycloudtab VALUES (:1, :2)");
if (!$s) {
    $m = oci_error($c);
    trigger_error("Could not parse statement: ". $m["message"], E_USER_ERROR);
}

foreach ($data as $record) {
    oci_bind_by_name($s, ":1", $record[0]);
    oci_bind_by_name($s, ":2", $record[1]);
    oci_execute($s, OCI_NO_AUTO_COMMIT); // for PHP <= 5.3.1 use OCI_DEFAULT instead
    if (!$r) {
        $m = oci_error($s);
        trigger_error("Could not execute statement: ". $m["message"], E_USER_ERROR);
    }
}
oci_commit($c);

// Query the data

$s = oci_parse($c, "SELECT * FROM mycloudtab");
if (!$s) {
    $m = oci_error($c);
    trigger_error("Could not parse statement: ". $m["message"], E_USER_ERROR);
}
$r = oci_execute($s);
if (!$r) {
    $m = oci_error($s);
    trigger_error("Could not execute statement: ". $m["message"], E_USER_ERROR);
}

echo "<table border='1'>\n";

// Print column headings

$ncols = oci_num_fields($s);
echo "<tr>\n";
for ($i = 1; $i <= $ncols; ++$i) {
    $colname = oci_field_name($s, $i);
    echo "<th><b>".htmlspecialchars($colname,ENT_QUOTES|ENT_SUBSTITUTE)."</b></th>\n";
}
echo "</tr>\n";

// Print data

while (($row = oci_fetch_array($s, OCI_ASSOC+OCI_RETURN_NULLS)) != false) {
    echo "<tr>\n";
    foreach ($row as $item) {
        echo "<td>";
        echo $item !== null ? htmlspecialchars($item, ENT_QUOTES|ENT_SUBSTITUTE) : "&nbsp;";
        echo "</td>\n";
    }
    echo "</tr>\n";
}
echo "</table>\n";

?>
