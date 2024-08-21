/*
 ** OKafka Java Client version 23.4.
 **
 ** Copyright (c) 2019, 2024 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */

package org.oracle.okafka.examples;

import java.util.Collections;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.KafkaFuture;
import org.oracle.okafka.clients.admin.AdminClient;
import org.oracle.okafka.clients.admin.DeleteTopicsResult;
import org.oracle.okafka.clients.admin.KafkaAdminClient;

public class OKafkaDeleteTopic {

    public static void main(String[] args) {
        Properties props = new Properties();
        //IP or Host name where Oracle Database 23c is running and Database Listener's Port
        props.put("bootstrap.servers", "localhost:1521");
        //name of the service running on the database instance
        props.put("oracle.service.name", "FREEPDB1");
        props.put("security.protocol","PLAINTEXT");
        // location for ojdbc.properties file where user and password properties are saved
        props.put("oracle.net.tns_admin",".");

		/*
		//Option 2: Connect to Oracle Autonomous Database using Oracle Wallet
		//This option to be used when connecting to Oracle autonomous database instance on OracleCloud
		props.put("security.protocol","SSL");
		// location for Oracle Wallet, tnsnames.ora file and ojdbc.properties file
		props.put("oracle.net.tns_admin",".");
		props.put("tns.alias","Oracle23ai_high");
		 */
        try (Admin admin = AdminClient.create(props)) {

            org.apache.kafka.clients.admin.DeleteTopicsResult delResult = admin.deleteTopics(Collections.singletonList("TXEQ"));

            //DeleteTopicsResult delResult = kAdminClient.deleteTopics(Collections.singletonList("TEQ2"), new org.oracle.okafka.clients.admin.DeleteTopicsOptions());

            Thread.sleep(5000);
            System.out.println("Auto Clsoing admin now");
        }
        catch(Exception e)
        {
            System.out.println("Exception while creating topic " + e);
            e.printStackTrace();
        }
    }

}
