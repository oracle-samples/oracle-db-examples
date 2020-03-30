/*
Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
*/

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.net.UnknownHostException;

/**
 * ConnectionHelperClient - a simple client for the ConnectionHelperServer<p/>
 * usage: <code>java -jar ConnectionHelperClient.jar connectionInfo [svrPort]</code><br/>
 * {@link #showUsage()}
 *  
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=ConnectionHelperClient">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ConnectionHelperClient {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		int svrPort = 51521; // 49152-65535 https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?search=1&page=24

		try {
			if (args.length > 1) {
				svrPort = Integer.parseInt(args[1]);
			}
			String connectionInfo = args[0];
			InetAddress localhost = InetAddress.getLocalHost();
	        try (
	                Socket svrSocket = new Socket(localhost, svrPort);
	                PrintWriter out =
	                    new PrintWriter(svrSocket.getOutputStream(), true);
	                BufferedReader in =
	                    new BufferedReader(
	                        new InputStreamReader(svrSocket.getInputStream()));
	            ) {
                    out.println(connectionInfo);
                    System.out.println(in.readLine()); // TODO: What kind of responses do we want?
	            } catch (UnknownHostException e) {
	                System.err.println("Don't know about host " + localhost);
	                System.exit(1);
	            } catch (IOException e) {
	                System.err.println("Couldn't get I/O for the connection to " +
	                    localhost+':'+svrPort);
	                System.exit(1);
	            } 		
	        } 
		catch (Throwable t) {
			t.printStackTrace();
			showUsage();
		}
	}

	/** <pre>
	"Usage: java -jar ConnectionHelperClient.jar connectionInfo [svrPort]\n" +
	"connectionInfo = -conName=user[/[pw]]@host:port(:sid|/svc)[#role]" +
	"Where:\n" + 
	"- connName is the name you would like for the connection\n" + 
	"- user is the user name for the schema you want to use\n" + 
	"- /password is the password for that user *(optional - if missing e.g., user@ or user/@, SQLDeveloper will prompt for it)*\n" + 
	"- host is the host that the database is on\n" + 
	"- port is the port the database is listening on\n" + 
	"- :sid is the sid for the database *(One of :sid or /svc MUST be supplied)*\n" + 
	"- /svc is the service name for the database  *(One of :sid or /svc MUST be supplied)*\n" + 
	"- #role is the role  *(optional - one of SYSDBA, SYSOPER, SYSBACKUP, SYSDG, SYSKM, SYSASM if used)*\n" + 
	"and\n" +
	"svrPort = the port the ConnectionHelperServer is listening on (optional default: 51521)\n";
	</pre>*/
	private static void showUsage() {
		String usage = "Usage: java -jar ConnectionHelperClient.jar connectionInfo [svrPort]\n" +
	                   "connectionInfo = -conName=user[/[pw]]@host:port(:sid|/svc)[#role]" +
	                   "Where:\n" + 
	                   "- connName is the name you would like for the connection\n" + 
	                   "- user is the user name for the schema you want to use\n" + 
	                   "- /password is the password for that user *(optional - if missing e.g., user@ or user/@, SQLDeveloper will prompt for it)*\n" + 
	                   "- host is the host that the database is on\n" + 
	                   "- port is the port the database is listening on\n" + 
	                   "- :sid is the sid for the database *(One of :sid or /svc MUST be supplied)*\n" + 
	                   "- /svc is the service name for the database  *(One of :sid or /svc MUST be supplied)*\n" + 
	                   "- #role is the role  *(optional - one of SYSDBA, SYSOPER, SYSBACKUP, SYSDG, SYSKM, SYSASM if used)*\n" + 
	                   "and\n" +
	                   "svrPort = the port the ConnectionHelperServer is listening on (optional default: 51521)\n";
		System.out.println(usage);
	}
}
