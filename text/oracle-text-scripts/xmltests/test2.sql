drop table purchase_orders;
CREATE TABLE purchase_orders (id   NUMBER,
                                doc  VARCHAR2(4000));

INSERT INTO purchase_orders (id, doc)
   VALUES (1,
           '<?xml version="1.0" encoding="UTF-8"?>
            <purchaseOrder xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                           xsi:noNamespaceSchemaLocation="xmlschema/po.xsd"
                           orderDate="1999-10-20">
              <shipTo country="US">
                <name>Alice Smith</name>
                <street>123 Maple Street</street>
                <city>Mill Valley</city>
                <state>CA</state>
                <zip>90952</zip>
              </shipTo>
              <billTo country="US">
                <name>Robert Smith</name>
                <street>8 Oak Avenue</street>
                <city>Old Town</city>
                <state>PA</state>
                <zip>95819</zip>
              </billTo>
              <comment>Hurry, my lawn is going wild!</comment>
              <items>
                <item partNum="872-AA">
                  <productName>Lawnmower</productName>
                  <quantity>1</quantity>
                  <USPrice>148.95</USPrice>
                  <comment>Confirm this is electric</comment>
                </item>
                <item partNum="926-AA">
                  <productName>Baby Monitor</productName>
                  <quantity>1</quantity>
                  <USPrice>39.98</USPrice>
                  <shipDate>1999-05-21</shipDate>
                </item>
              </items>           </purchaseOrder>');

Execute ctx_ddl.drop_section_group('MyGroup')

Execute ctx_ddl.create_section_group('MyGroup','XML_SECTION_GROUP')
Execute ctx_ddl.add_attr_section('MyGroup', 'billTo@country', 'billTo@country')

Create index CTXtest on purchase_orders(doc) indextype is ctxsys.context  parameters ('section group MyGroup');

SELECT id FROM purchase_orders
   WHERE contains(doc, 'US within billTo@country') > 0;
