/*
 ** OKafka Java Client version 23.4.
 **
 ** Copyright (c) 2019, 2024 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */

package org.oracle.okafka.examples;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.*;
import java.util.concurrent.ExecutionException;

import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.DeleteTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.KafkaFuture;

import org.oracle.okafka.clients.admin.AdminClient;

public class OKafkaAdminTopic {

    public static void main(String[] args) {
        System.setProperty("org.slf4j.simpleLogger.defaultLogLevel", "INFO");

        // Get application properties
        Properties appProperties = null;
        try {
            appProperties = getProperties();
            if (appProperties == null) {
                System.out.println("Application properties not found!");
                System.exit(-1);
            }
        } catch (Exception e) {
            System.out.println("Application properties not found!");
            System.out.println("Exception: " + e);
            System.exit(-1);
        }

        if (args.length < 2) {
            System.out.println("Usage: java OKafkaAdminTopic [CREATE|DELETE] topic1 ... topicN");
            return;
        }

        ArrayList<String> topicsName = new ArrayList<>();
        for (int i = 1; i < args.length; i++) {
            topicsName.add(args[i]);
        }

        String operation = args[0].toUpperCase();
        switch (operation) {
            case "CREATE":
                createTopic(appProperties, topicsName);
                break;

            case "DELETE":
                deleteTopic(appProperties, topicsName);
                break;

            default:
                System.out.println("Error: Invalid operation.");
        }

    }

    private static void createTopic(Properties appProperties, ArrayList<String> topicsName) {
        try (Admin admin = AdminClient.create(appProperties)) {
            //Create Topic named TXEQ_1 and TXEQ_2 with 10 Partitions.

            ArrayList<NewTopic> topics = new ArrayList<>();

            for (String topicName : topicsName) {
                NewTopic nt = new NewTopic(topicName, 10, (short)0);
                topics.add(nt);
            }

            CreateTopicsResult result = admin.createTopics(topics);
            try {
                KafkaFuture<Void> ftr =  result.all();
                ftr.get();
            } catch ( InterruptedException | ExecutionException e ) {
                throw new IllegalStateException(e);
            }

            System.out.println("Topic(s) created. Closing OKafka admin now");
        }
        catch(Exception e)
        {
            System.out.println("Exception while creating topic " + e);
            e.printStackTrace();
        }
    }

    private static void deleteTopic(Properties appProperties, ArrayList<String> topicsName) {
        try (Admin admin = AdminClient.create(appProperties)) {
            DeleteTopicsResult delResult = admin.deleteTopics(topicsName);
            Thread.sleep(5000);
            System.out.println("Closing  OKafka admin now");
        }
        catch(Exception e)
        {
            System.out.println("Exception while deleting topic " + e);
            e.printStackTrace();
        }
    }

    private static Properties getProperties()  throws IOException {
        InputStream inputStream = null;
        Properties appProperties = null;

        try {
            Properties prop = new Properties();
            String propFileName = "config.properties";
            inputStream = OKafkaAdminTopic.class.getClassLoader().getResourceAsStream(propFileName);
            if (inputStream != null) {
                prop.load(inputStream);
            } else {
                throw new FileNotFoundException("property file '" + propFileName + "' not found.");
            }
            appProperties = prop;

        } catch (Exception e) {
            System.out.println("Exception: " + e);
            throw e;
        } finally {
            inputStream.close();
        }
        return appProperties;
    }
}
