package com.oracle.kafka.teq;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Properties;

import org.json.simple.JSONObject;

import com.github.javafaker.Faker;

public class Utility {
	 
	/**
     * Gets a Properties information from the file src/main/resources/config.properties
     *
     * @return The Properties object
     * @throws Exception Thrown if the file config.properties is not available
     *                   in the directory src/main/resources
     */
    public static Properties getProperties() throws Exception {

        Properties props = null;
        try (InputStream input = Producer.class.getClassLoader().getResourceAsStream("config.properties")) {

            props = new Properties();

            if (input == null) {
                throw new Exception("The configuration file config.properties could not be found.");
            }
            props.load(input);
        } catch (IOException ex) {
            ex.printStackTrace();
        }
        
        return props;
    }
    
    /**
     * Generates a random message to produce to a Kafka topic.
     * 
     * @param num The number to set for the message.
     * @return The generated message.
     */
    public static String generateRandomMessage(int num) {
    	Faker faker = new Faker();
    	HashMap<String,String> fakeData = new HashMap<>();
    	fakeData.put("Message Number", Integer.toString(num));
    	fakeData.put("firstName", faker.name().firstName());
    	fakeData.put("lastName", faker.name().lastName());
    	fakeData.put("Job Skills", faker.job().keySkills());
         
    	return new JSONObject(fakeData).toString();
    }


}
