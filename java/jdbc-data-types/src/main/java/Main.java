/* Copyright (c) 2021, 2022, Oracle and/or its affiliates.
This software is dual-licensed to you under the Universal Permissive License
(UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
either license.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
https://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

DESCRIPTION
Main - Runner class calling multiple methods demonstrating data types: JSON, XML, PL/SQL Associative Arrays and REF Cursors
*/

import database.DatabaseService;
import database.DatabaseServiceWithPooling;
import moreexamples.BlogExamples;
import oracle.jdbc.OracleType;
import oracle.jdbc.OracleTypes;
import oracle.jdbc.internal.OracleClob;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import oracle.xdb.XMLType;
import oracle.xml.parser.v2.*;

import javax.xml.transform.dom.DOMSource;
import java.sql.*;
import java.util.Scanner;
import java.util.stream.IntStream;

public class Main {

    private static DatabaseService ods;
    private static DatabaseServiceWithPooling pds;

    /**
     * Runner method
     * @param args unused
     */
    public static void main(String[] args) {
        try {
            ods = new DatabaseService();
            pds = new DatabaseServiceWithPooling();

            Scanner runFunctionChallenge = new Scanner(System.in);
            boolean keepGoing = true;

            while(keepGoing) {
                System.out.print("Run Function: ");
                String functionName = runFunctionChallenge.next();
                System.out.println("Output: ==========================================");
                switch (functionName) {
                    case "readJSONExampleA" -> readJSONExampleA();
                    case "readJSONExampleB" -> readJSONExampleB();
                    case "readJSONExampleC" -> readJSONExampleC();
                    case "readJSONExampleD" -> readJSONExampleD();
                    case "readJSONExampleE" -> readJSONExampleE();
                    case "readJSONExampleF" -> readJSONExampleF();
                    case "readJSONExampleG" -> readJSONExampleG();
                    case "writeJSONExampleA" -> {writeJSONExampleA(); readJSONExampleA();}
                    case "writeJSONExampleB" -> {writeJSONExampleB(); readJSONExampleA();}
                    case "updateJSONExampleA" -> {updateJSONExampleA(); readJSONExampleA();}
                    case "updateJSONExampleB" -> {updateJSONExampleB(); readJSONExampleA();}
                    case "updateJSONExampleC" -> {updateJSONExampleC(); readJSONExampleA();}
                    case "readXMLExampleA" -> readXMLExampleA();
                    case "readXMLExampleB" -> readXMLExampleB();
                    case "readXMLExampleC" -> readXMLExampleC();
                    case "readXMLExampleD" -> readXMLExampleD();
                    case "writeXMLExampleA" -> {writeXMLExampleA(); readXMLExampleA();}
                    case "writeXMLExampleB" -> {writeXMLExampleB(); readXMLExampleA();}
                    case "updateXMLExampleA" -> {updateXMLExampleA(); readXMLExampleA();}
                    case "updateXMLExampleB" -> {updateXMLExampleB(); readXMLExampleA();}
                    case "updateXMLExampleC" -> {updateXMLExampleC(); readXMLExampleA();}
                    case "readWithAssociativeArrays" -> readWithAssociativeArrays(1);
                    case "readWithRefCursorA" -> readWithRefCursorA();
                    case "readWithRefCursorB" -> readWithRefCursorB();
                    case "readWithRefCursorC" -> readWithRefCursorC();
                    case "blogExampleA" -> BlogExamples.blogExampleA(pds);
                    case "blogExampleB" -> BlogExamples.blogExampleB(pds);
                    case "blogExampleC" -> BlogExamples.blogExampleC(pds);
                    case "blogExampleD" -> BlogExamples.blogExampleD(pds);
                    case "blogExampleE" -> BlogExamples.blogExampleE(pds);
                    case "end" -> keepGoing = false;
                    default -> System.out.printf("Error: function %s not found.\n", functionName);
                }
                System.out.println();
            }



        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * Retrieves productInformation from every product as a JSON string
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readJSONExampleA() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        PreparedStatement retrieve_stmt = connection.prepareStatement("select productInformation from products");
        ResultSet rs = retrieve_stmt.executeQuery();

        while (rs.next()) {
            String productInformation = rs.getObject("productInformation", String.class);
            System.out.println(productInformation);
        }
    }

    /**
     * Retrieves productInformation from every product, and reading the expected Title attribute inside the JSON
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readJSONExampleB() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        PreparedStatement retrieve_stmt = connection.prepareStatement("select productInformation from products");
        ResultSet rs = retrieve_stmt.executeQuery();

        while (rs.next()) {
            OracleJsonObject productInformation = rs.getObject("productInformation", OracleJsonObject.class);
            try {
                String author = productInformation.getString("Author"); // may throw NPE
                System.out.println("Author: " + author);
            } catch (NullPointerException e) {
                System.out.println("Author: Unknown");
            }


        }
    }

    /**
     * Retrieves Authors from every product as a JSON string, using Simple Dot-Notation. If the Author attribute does
     * NOT exist inside productInformation JSON object, getString will return null
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readJSONExampleC() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        PreparedStatement retrieve_stmt = connection.prepareStatement("select p.productInformation.Author author from products p");
        ResultSet rs = retrieve_stmt.executeQuery();

        while (rs.next()) {
            String author = rs.getString("author");
            System.out.println("Author: " + author);
        }
    }

    /**
     * Retrieves productInformation from every product as a JSON string, using the json_exists condition to filter in
     * JSON with an Author attribute
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readJSONExampleD() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        PreparedStatement retrieve_stmt = connection.prepareStatement("select productInformation from products where json_exists(productInformation, '$.Author')");
        ResultSet rs = retrieve_stmt.executeQuery();

        while (rs.next()) {
            OracleJsonObject productInformation = rs.getObject("productInformation", OracleJsonObject.class);
            String title = productInformation.getString("Author");
            System.out.println("Author: " + title);
        }
    }

    /**
     * Retrieves productInformation from every product as a JSON string, with a where clause checking an
     * attribute inside productInformation JSON object
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readJSONExampleE() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        PreparedStatement retrieve_stmt = connection.prepareStatement("select productInformation from products p where p.productInformation.Author IS NOT NULL");
        ResultSet rs = retrieve_stmt.executeQuery();

        while (rs.next()) {
            OracleJsonObject productInformation = rs.getObject("productInformation", OracleJsonObject.class);
            String author = productInformation.getString("Author");
            System.out.println("Author: " + author);
        }
    }

    /**
     * Retrieves productInformation from every product with filter on attributes inside the JSON column
     * with more comparison operators
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readJSONExampleF() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        PreparedStatement retrieve_stmt = connection.prepareStatement("select productInformation from products p where p.productInformation.ProductType.string() = :1 and p.productInformation.Stock.number() > 0");
        retrieve_stmt.setString(1, "Book");
        ResultSet rs = retrieve_stmt.executeQuery();

        while (rs.next()) {
            OracleJsonObject productInformation = rs.getObject("productInformation", OracleJsonObject.class);
            String title = productInformation.getString("Title");
            int stock = productInformation.getInt("Stock");
            System.out.printf("Title: %s, Stock: %d\n", title, stock);
        }
    }

    /**
     * Retrieves list of orders from a table as JSON, generated by using JSON_OBJECT and JSON_ARRAYAGG.
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readJSONExampleG() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        String json_generation_query = "SELECT json_object('invoice_id' : order_invoice_id, 'order_date' : order_date, 'orders' : json_arrayagg(json_object('product_id' : productId, 'ct' : order_count)) returning JSON) \"order\" FROM orders group by order_invoice_id, order_date";
        PreparedStatement retrieve_stmt = connection.prepareStatement(json_generation_query);
        ResultSet rs = retrieve_stmt.executeQuery();

        while (rs.next()) {
            String orderInformation = rs.getObject("order", String.class);
            System.out.println(orderInformation);
        }
    }


    /**
     * Inserts a new product by creating a new OracleJSONObject and binding it as OracleType.JSON
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void writeJSONExampleA() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        OracleJsonFactory factory = new OracleJsonFactory();
        OracleJsonObject product = factory.createObject();
        product.put("ProductName", "Universal Gaming Controller");
        product.put("ProductType", "Electronics");
        product.put("Manufacturer", "Uni Electronics");
        product.put("Stock", 12);

        PreparedStatement insert_stmt = connection.prepareStatement("insert into products(productInformation) values (:1)");
        insert_stmt.setObject(1, product, OracleType.JSON);
        insert_stmt.executeUpdate();
    }

    /**
     * Inserts a new product with a JSON String and binding it as a OracleType.VARCHAR2
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void writeJSONExampleB() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        String jsonStringPayload = "{\"ProductName\":\"Universal Gaming Controller\", \"Manufacturer\":\"Elite Corporation\", \"Stock\":12}";

        PreparedStatement insert_stmt = connection.prepareStatement("insert into products(productInformation) values (:1)");
        insert_stmt.setObject(1, jsonStringPayload, OracleType.VARCHAR2);
        int inserts = insert_stmt.executeUpdate();
        System.out.println(inserts + " record(s) inserted.");

    }

    /**
     * Updating product productInformation using whole document replacement
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void updateJSONExampleA() throws SQLException {
        Connection connection = ods.getDatabaseConnection();
        long requestProductId = 1;
        int purchaseCount = 1;

        PreparedStatement retrieve_stmt = connection.prepareStatement("select productInformation from products p where productId = :1");
        retrieve_stmt.setLong(1, requestProductId);
        ResultSet rs = retrieve_stmt.executeQuery();

        if (!rs.next()) {
            System.out.println("Error: product with productId " + requestProductId + " not found.");
            return;
        }

        OracleJsonObject product = rs.getObject(1, OracleJsonObject.class); // retrieve original productInformation from database

        OracleJsonFactory factory = new OracleJsonFactory();
        product = factory.createObject(product); // create object from original productInformation and reassign product
        product.put("Stock", product.getInt("Stock") - purchaseCount); // update Stock attribute

        PreparedStatement update_stmt = connection.prepareStatement("update products p set p.productInformation = :1 where p.productId = :2");
        update_stmt.setObject(1, product, OracleType.JSON);
        update_stmt.setLong(2, requestProductId);
        int updates = update_stmt.executeUpdate();
        System.out.println(updates + " record(s) updated.");
    }

    /**
     * Updating a record using JSON_TRANSFORM, which is a general modification function and modifies JSON documents.
     * This example updates the Stock attribute inside the productInformation JSON column
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void updateJSONExampleB() throws SQLException {
        Connection connection = ods.getDatabaseConnection();
        long requestProductId = 1;
        int newShipmentCount = 10;

        PreparedStatement update_stmt = connection.prepareStatement("update products p set p.productInformation = JSON_TRANSFORM(p.productInformation, SET '$.Stock' = p.productInformation.Stock.number() + :1) where p.productId = :2");
        update_stmt.setObject(1, newShipmentCount);
        update_stmt.setLong(2, requestProductId);
        int updates = update_stmt.executeUpdate();
        System.out.println(updates + " record(s) updated.");
    }

    /**
     * Updating a record using JSON_MERGEPATCH, which is used to update specific portions of a JSON document.
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void updateJSONExampleC() throws SQLException {
        Connection connection = ods.getDatabaseConnection();
        long requestProductId = 2;

        OracleJsonFactory factory = new OracleJsonFactory();
        OracleJsonObject productUpdate = factory.createObject();
        productUpdate.put("Genre", "Non-Fiction"); // adds new attribute
        productUpdate.put("Stock", 10); // update existing attribute
        productUpdate.putNull("Author"); // json_mergepatch removes attributes with null value

        PreparedStatement update_stmt = connection.prepareStatement("update products p set p.productInformation = JSON_MERGEPATCH(p.productInformation, :1) where p.productId = :2");
        update_stmt.setObject(1, productUpdate);
        update_stmt.setLong(2, requestProductId);
        int updates = update_stmt.executeUpdate();
        System.out.println(updates + " record(s) updated.");
    }

    /**
     * Retrieves invoice from every record as a string
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readXMLExampleA() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        PreparedStatement retrieve_stmt = connection.prepareStatement("select invoice from invoices");
        ResultSet rs = retrieve_stmt.executeQuery();

        while (rs.next()) {
            XMLType detailsXML = rs.getObject(1, XMLType.class);
            System.out.println(detailsXML.getString());

        }
    }

    /**
     * Retrieves every invoice and gets the ProductId node inside to print and retrieve the productIds on the invoice
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readXMLExampleB() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        PreparedStatement retrieve_stmt = connection.prepareStatement("select invoiceId, invoice from invoices i");
        ResultSet rs = retrieve_stmt.executeQuery();

        while(rs.next()) {
            int invoiceId = rs.getInt(1);
            SQLXML sqlxml = rs.getSQLXML(2); // gets invoice column as an NClob object
            DOMSource domSource = sqlxml.getSource(DOMSource.class); // creates a source for reading XML values
            XMLDocument doc = (XMLDocument) domSource.getNode(); // retrieves the whole node
            XMLNodeList productsNodeList = (XMLNodeList) doc.getElementsByTagName("ProductId"); // finds tag ProductId

            IntStream.range(0, productsNodeList.getLength()).forEach(n -> {
                XMLElement productIdElement = (XMLElement) productsNodeList.item(n);
                System.out.println("Invoice = " + invoiceId + ", " + "ProductId = " + productIdElement.getTextContent());
            });

        }
    }

    /**
     * Retrieves only the ShippingAddress node for a specific invoice with the specified invoiceId
     * and retrieves elements using another approach.
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readXMLExampleC() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        PreparedStatement retrieve_stmt = connection.prepareStatement("select xmlquery('/Invoice/ShippingInformation/ShippingAddress' PASSING i.invoice returning content) xml from invoices i where XMLExists('$po/Invoice[InvoiceId=$iid]' PASSING i.invoice as \"po\", :1 as \"iid\")");
        retrieve_stmt.setInt(1, 272);
        ResultSet rs = retrieve_stmt.executeQuery();

        while(rs.next()) {
            SQLXML sqlxml = rs.getSQLXML(1);
            DOMSource domSource = sqlxml.getSource(DOMSource.class); // creates a source for reading XML values
            XMLDocument doc = (XMLDocument) domSource.getNode(); // retrieves the whole node

            XMLNodeList addressNl = (XMLNodeList) doc.getElementsByTagName("Address"); // finds tag Address
            XMLElement addressElement = (XMLElement) addressNl.item(0); // NodeList only contains Address Element
            String address = addressElement.getTextContent();


            XMLNodeList cityNl = (XMLNodeList) doc.getElementsByTagName("City"); // finds tag City
            XMLElement cityElement = (XMLElement) cityNl.item(0) ; // NodeList only contains City Element
            String city = cityElement.getTextContent();

            XMLNodeList stateNl = (XMLNodeList) doc.getElementsByTagName("State"); // finds tag State
            XMLElement stateElement = (XMLElement) stateNl.item(0); // NodeList only contains State Element
            String state = stateElement.getTextContent();

            System.out.println("Address = " + address + " " + city + ", " + state);
        }

    }

    /**
     * Retrieves list of orders from a table as XML, generated by using XMLELEMENT and XMLAGG.
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void readXMLExampleD() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        String xml_generation_query = """
        select XMLELEMENT("Invoice", 
            XMLELEMENT("InvoiceId", ORDER_INVOICE_ID), 
            XMLELEMENT("OrderDate", ORDER_DATE), 
            XMLElement("Orders", XMLAGG(XMLELEMENT("Order", 
                XMLELEMENT("productId", PRODUCTID), 
                XMLELEMENT("ct", ORDER_COUNT))))) as "order"
        from orders group by order_invoice_id, order_date
        """;
        PreparedStatement retrieve_stmt = connection.prepareStatement(xml_generation_query);
        ResultSet rs = retrieve_stmt.executeQuery();

        while (rs.next()) {
            XMLType detailsXML = (XMLType) rs.getObject(1);
            System.out.println(detailsXML.getString());
        }
    }

    /**
     * Inserts a new invoice record from an XML String, then inserted as SQLXML.
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void writeXMLExampleA()  throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        String xmlStringPayload = "<?xml version=\"1.0\"?><Invoice><InvoiceId>273</InvoiceId><OrderStatus>Received</OrderStatus></Invoice>";
        SQLXML sqlxml = connection.createSQLXML();
        sqlxml.setString(xmlStringPayload);

        PreparedStatement insert_stmt = connection.prepareStatement("insert into invoices(invoice) values (:1)");
        insert_stmt.setSQLXML(1, sqlxml);
        int inserts = insert_stmt.executeUpdate();
        System.out.println(inserts + " record(s) inserted.");

    }

    /**
     * Inserts a new invoice record using an OracleClob created from the XML String. This is used
     * to load a large XML document into the database. Note the casting of the bind variable 1 into XMLType.
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void writeXMLExampleB() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        String xmlStringPayload = "<?xml version=\"1.0\"?><Invoice><InvoiceId>274</InvoiceId><OrderStatus>Cancelled</OrderStatus></Invoice>";

        OracleClob clob = (OracleClob)connection.createClob();
        clob.setString(1, xmlStringPayload);

        PreparedStatement insert_stmt = connection.prepareStatement("insert into invoices(invoice) values (XMLType(:1))");
        insert_stmt.setObject(1, clob);
        int inserts = insert_stmt.executeUpdate();
        System.out.println(inserts + " record(s) inserted.");
    }

    /**
     * Updates entire XML Document using SQLXML
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void updateXMLExampleA() throws SQLException {
        Connection connection = ods.getDatabaseConnection();
        int invoiceId = 1;

        PreparedStatement update_stmt = connection.prepareStatement("update invoices set invoice = :1 where invoiceId = :2");
        String xmlString = "<?xml version=\"1.0\"?><Invoice><InvoiceId>273</InvoiceId><OrderStatus>Cancelled</OrderStatus></Invoice>";

        SQLXML sqlxml = connection.createSQLXML();
        sqlxml.setString(xmlString);

        update_stmt.setSQLXML(1, sqlxml);
        update_stmt.setInt(2, invoiceId);
        int u = update_stmt.executeUpdate();
        System.out.println(u + " record(s) updated.");

    }

    /**
     * Updates the value of the Invoice/OrderStatus node, for a specific invoice with a matching InvoiceId
     * using XMLExists
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void updateXMLExampleB() throws SQLException {
        Connection connection = ods.getDatabaseConnection();
        String newStatus = readWithAssociativeArrays(2); // looks up string value of equivalent status given an ID
        int invoiceId = 274;

        String update_string = """
            update invoices i
                set i.invoice = XMLQuery('copy $new := $current modify (
                    for $status in $new/Invoice/OrderStatus return replace value of node $status with $newStatus
                ) return $new' PASSING i.invoice as "current", :1 as "newStatus" RETURNING CONTENT)
            where XMLExists('$i/Invoice[InvoiceId=$iid]' PASSING i.invoice as "i", :2 as "iid")
        """;

        PreparedStatement update_stmt = connection.prepareStatement(update_string);


        update_stmt.setString(1, newStatus);
        update_stmt.setInt(2, invoiceId);
        int u = update_stmt.executeUpdate();
        System.out.println(u + " record(s) updated.");
    }

    /**
     * Updates XML Document by inserting a new node inside the invoice, for a specific invoice with a matching InvoiceId
     * using XMLExists
     *
     * @throws SQLException if a Database error occurs. This function is simplified
     * to handle it where the function is called
     */
    private static void updateXMLExampleC() throws SQLException {
        Connection connection = ods.getDatabaseConnection();
        String newNode = "<Orders><Order><ProductId>2</ProductId><Count>2</Count></Order></Orders>";
        int invoiceId = 274;

        String update_string = """
            update invoices i
                set i.invoice = XMLQuery('copy $new := $current modify (
                    for $invoice in $new/Invoice return insert nodes $newOrder as last into $invoice
                ) return $new' PASSING i.invoice as "current", :1 as "newOrder" RETURNING CONTENT)
            where XMLExists('$i/Invoice[InvoiceId=$iid]' PASSING i.invoice as "i", :2 as "iid")
        """;

        PreparedStatement update_stmt = connection.prepareStatement(update_string);
        SQLXML sqlxml = connection.createSQLXML();
        sqlxml.setString(newNode);

        update_stmt.setSQLXML(1, sqlxml);
        update_stmt.setInt(2, invoiceId);
        int u = update_stmt.executeUpdate();
        System.out.println(u + " record(s) updated.");
    }


    /**
     * Retrieves string equivalent of order status given a statusId, by calling a procedure that leverages
     * the Associative Array data type
     * @throws SQLException if a Database error occurs.
     */
    private static String readWithAssociativeArrays(int statusId) throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        CallableStatement call = connection.prepareCall("{ call get_order_status(?, ?) }");

        call.setInt(1, statusId);
        call.registerOutParameter(2, OracleType.VARCHAR2);
        call.execute();

        String statusValue = call.getString(2);
        System.out.println("Status: " + statusValue);
        return statusValue;

    }

    /**
     * Retrieves productInformation from the products Table, by calling a procedure call leveraging REF Cursors.
     *
     * @throws SQLException if a Database error occurs. This function is simplified to handle it where the function is called
     */
    private static void readWithRefCursorA() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        CallableStatement call = connection.prepareCall("{ ? = call get_information() }");

        call.registerOutParameter(1, OracleTypes.REF_CURSOR);
        call.execute();

        ResultSet rs = (ResultSet) call.getObject(1);
        while (rs.next()) {
            String productInformation = rs.getObject("productInformation", String.class);
            System.out.println("Information: " + productInformation);
        }
    }


    /**
     * Retrieves productInformation from the products Table, by calling a procedure call leveraging REF Cursors.
     *
     * @throws SQLException if a Database error occurs. This function is simplified to handle it where the function is called
     */
    private static void readWithRefCursorB() throws SQLException {
        Connection connection = ods.getDatabaseConnection();

        CallableStatement call = connection.prepareCall("{ call products_data.open_prod_cv_a(?) }");

        call.registerOutParameter(1, OracleTypes.REF_CURSOR);
        call.execute();

        ResultSet rs = (ResultSet) call.getObject(1);
        while (rs.next()) {
            String productInformation = rs.getObject("productInformation", String.class);
            System.out.println("Product Information: " + productInformation);
        }
    }


    /**
     * Retrieves column 2 from the varying tables, by calling a procedure call leveraging REF Cursors.
     *
     * @throws SQLException if a Database error occurs. This function is simplified to handle it where the function is called
     */
    private static void readWithRefCursorC() throws SQLException {
        Connection connection = ods.getDatabaseConnection();
        String sourceTable = "Products";

        CallableStatement call = connection.prepareCall("{ call products_data.open_prod_cv_b(?, ?) }");
        call.registerOutParameter(1, OracleTypes.REF_CURSOR);
        call.setString(2, sourceTable);
        call.execute();

        ResultSet rs = (ResultSet) call.getObject(1);
        while (rs.next()) {
            String productInformation = rs.getObject(2, String.class);
            System.out.println("Table Column #2: " + productInformation);
        }
    }

}
