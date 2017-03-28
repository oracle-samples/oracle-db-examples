/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved. */

/******************************************************************************
 *
 * You may not use the identified files except in compliance with The MIT 
 * License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at
 * https://github.com/oracle/oracle-db-examples/blob/master/dotnet/LICENSE
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * NAME
 *   oraclejsonclob.cs
 *
 * DESCRIPTION
 *   Inserts one row into a JSON table using CLOB storage.
 *   Executes a query against a JSON table using CLOB storage.
 *   This sample works with either ODP.NET, Managed Driver or 
 *   ODP.NET, Unmanaged Driver.
 *   
 *   Requires Oracle Database 12.1.0.2 or higher, which has JSON datatype support.
 *   See http://docs.oracle.com/database/121/ADXDB/json.htm#CACGCBEG
 *   Use SQL below to create the required table or do:
 *
DROP TABLE j_purchaseorder_c;
-- The extra CHECK clause 'or length(po_document) = 0' clause allows
-- EMPTY_CLOB() to be inserted into the table.  The extra clause is
-- not needed if you have a database patch for bug 21636362.  The
-- extra 'or' clause will stop the table appearing in
-- USER_JSON_COLUMNS.  EMPTY_CLOB() is currently needed by
-- node-oracledb for inserting CLOB data.
CREATE TABLE j_purchaseorder_c (po_document CLOB CHECK (po_document IS JSON or length(po_document) = 0));
COMMIT;
 * 
 *
 *****************************************************************************/

using System;
using Oracle.ManagedDataAccess.Client;
// using Oracle.DataAccess.Client;

namespace JsonClobSample
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                // Add your user id, password, and data source
                string conString = "User Id=<user>;Password=<password>;Data Source=<data source>;";
                
                // Connect and open a database connection
                OracleConnection con = new OracleConnection();
                con.ConnectionString = conString;
                con.Open();

                // Insert JSON data into database using a CLOB
                OracleCommand cmd = con.CreateCommand();
                cmd.CommandText = "INSERT INTO j_purchaseorder_c (po_document) VALUES (:1)";

                OracleParameter param = new OracleParameter();
                param.OracleDbType = OracleDbType.Clob;
                param.Value = @"{'id': 1,'name': 'Alex', 'location': 'USA'}";
                cmd.Parameters.Add(param);

                cmd.ExecuteNonQuery();

                Console.WriteLine("JSON inserted.");
                Console.WriteLine();

                // Query JSON from database
                cmd.CommandText = "SELECT po_document FROM j_purchaseorder_c WHERE JSON_EXISTS (po_document, '$.location')";
                OracleDataReader rdr = cmd.ExecuteReader();

                rdr.Read();
                Console.WriteLine(rdr.GetString(0));

            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.InnerException);
            }

        }
    }
}
