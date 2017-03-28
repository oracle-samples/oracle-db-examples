/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved. */

/******************************************************************************
 *
 * You may not use the identified files except in compliance with The MIT
 * License (the "License.")
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
 *   oraclejson.cs
 *
 * DESCRIPTION
 *   Inserts one row into a JSON table.
 *   Executes a query against a JSON table.
 *   This sample works with either ODP.NET, Managed Driver or 
 *   ODP.NET, Unmanaged Driver.
 *   
 *   Requires Oracle Database 12.1.0.2 or higher, which has JSON datatype support.
 *   See http://docs.oracle.com/database/121/ADXDB/json.htm#CACGCBEG
 *   Use SQL below to create the required table or do:
 *
 *   DROP TABLE j_purchaseorder;
 *   CREATE TABLE j_purchaseorder
 *   (po_document VARCHAR2(4000) CONSTRAINT ensure_json CHECK (po_document IS JSON));
 *   
 *
 *****************************************************************************/

using System;
using Oracle.ManagedDataAccess.Client;
//using Oracle.DataAccess.Client;

namespace JsonSample
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

                // Insert JSON data into database
                OracleCommand cmd = con.CreateCommand();
                cmd.CommandText = "INSERT INTO j_purchaseorder (po_document) VALUES (:1)";

                OracleParameter param = new OracleParameter();
                param.OracleDbType = OracleDbType.Varchar2;
                param.Value = @"{'id': 1,'name': 'Alex', 'location': 'USA'}";
                cmd.Parameters.Add(param);

                cmd.ExecuteNonQuery();

                Console.WriteLine("JSON inserted.");
                Console.WriteLine();

                // Query JSON from database
                cmd.CommandText =  "SELECT po_document FROM j_purchaseorder WHERE JSON_EXISTS (po_document, '$.location')";
                OracleDataReader rdr = cmd.ExecuteReader();

                rdr.Read();
                Console.WriteLine(rdr.GetOracleValue(0));

            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.InnerException);
            }

        }
    }
}
