package com.oracle.kafka.teq;

import java.util.Locale;

public class Application {

	public static void main(String[] args) throws Exception {
		String errorStr = "ERROR: Enter the first parameter as Producer or Consumer and specify the topic name as the second parameter.";

		if (args.length < 1) {
			System.out.println(errorStr);
			return;
		}

		String mode = args[0];
		String topicName = args[1];
		int produceMsgCount = 0;
		if (args.length > 2)
			produceMsgCount = Integer.parseInt(args[2]);

		switch (mode.toLowerCase(Locale.ROOT)) {
		case "consumer":
			System.out.println("Starting the Consumer\n");
			new Consumer().runConsumer(topicName);
			break;
		case "producer":
			System.out.println("Starting the Producer\n");
			new Producer().runProducer(topicName, produceMsgCount);
			break;
		default:
			System.out.println(errorStr);
		}
	}
}
