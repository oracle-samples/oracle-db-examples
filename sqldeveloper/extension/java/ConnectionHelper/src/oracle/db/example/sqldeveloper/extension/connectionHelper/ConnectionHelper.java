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

package oracle.db.example.sqldeveloper.extension.connectionHelper;

import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import oracle.dbtools.raptor.standalone.connection.ConnectionUtils;
import oracle.dbtools.util.Logger;
import oracle.ide.Ide;
import oracle.ide.cmd.ExitCommand;
import oracle.ide.cmd.ShutdownHook;

/**
 * ConnectionHelper - Where the 'do the work' stuff lives
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelper">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ConnectionHelper {

	// Only process command line args once no matter how many times 
	// the preference is changed while running
	private static boolean processedCommandLineArgs;
	
	/**
	 * Process each command line argument as a potential connection request
	 */
	public static void processCommandLineArgs() {
		if (!processedCommandLineArgs) {
	        String[] args = Ide.getIdeArgs().getArgs();
	        boolean persist = ConnectionHelperPreferenceModel.getInstance().isPersistCommandLineConnections();
	        for (String arg : args) {
	        	System.out.println(arg);
	        	ConnectionHelper.processPotentialConnectionArgument(arg, persist);
	        }
	        processedCommandLineArgs = true;
		}
	}

	/**
	 * Process the string received by the ConnectionHelperServer as a potential connection request
	 * @param arg
	 */
	public static void processPotentialConnectionRequest(String arg) {
		processPotentialConnectionArgument(arg, ConnectionHelperPreferenceModel.getInstance().isPersistExternalConnectionServerConnections());
	}

	// -system_DB120101=system/dbtools@llg00hon.uk.oracle.com:1521/DB12201
    // -sysdba_DB120101=sys/dbtools@llg00hon.uk.oracle.com:1521/DB12201#SYSDBA
    // TODO? Look up valid character requirements for each group
    // format = -conName=user[/[pw]]@host:port(:sid|/svc)[#role]
    //           1       2      4    5    6     8    9     11
    private static final String conRegex = "-(.*)=([^\\/]*)(\\/([^@]*))?@([^:]*):([^:]*)(:([a-zA-Z0-9_]*)|\\/([a-zA-Z0-9_]*))(#([a-zA-Z0-9_]*))?"; //$NON-NLS-1$
    private static final Pattern conArg = Pattern.compile(conRegex);
	
    private static void processPotentialConnectionArgument(String arg, boolean persist) {
        Matcher m = conArg.matcher(arg);
        if (m.matches()) {
            String connName = m.group(1);
            String userName = m.group(2);
            String password = m.group(4);
            String host = m.group(5);
            String port = m.group(6);
            String sid = m.group(8);
            String service = m.group(9);
            String role = m.group(11);
            String folder = persist
            		        ? ConnectionHelperResources.getString(ConnectionHelperResources.PERSISTENT)
            		        : ConnectionHelperResources.getString(ConnectionHelperResources.TRANSIENT);		
            
            
            ConnectionUtils.addConnection(connName, userName, password, sid, host, port, false/*osAuth*/, service, role, folder);
            final String fqName = ConnectionUtils.getFqConnectionName(connName);
            ConnectionUtils.connect(fqName);
            
            if (!persist) {
            	if (null == shutdownHook) {
            		shutdownHook = new ConnectionHelperShutdownHook();
            		ExitCommand.addShutdownHook(shutdownHook);
            	}
            	shutdownHook.add(fqName);
            }
        }
	}
    
    private static ConnectionHelperShutdownHook shutdownHook;

	/**
	 * ConnectionHelperShutdownHook - a shutdown hook to process transient connections
	 *
	 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelper.ConnectionHelperShutdownHook">Brian Jeffries</a>
	 * @since SQL Developer 20.1
	 */
	private static class ConnectionHelperShutdownHook implements ShutdownHook {
		public ArrayList<String> fqNames = new ArrayList<>();
		
		public void add(String fqName) {
			fqNames.add(fqName);
		}
		
		@Override
		public boolean canShutdown() {
			return true;
		}

		@Override
		public void shutdown() {
			for (String fqName : fqNames) {
				try {
					ConnectionUtils.closeAndDeleteConnection(fqName);
				}
				catch (Throwable t) {
					Logger.warn(getClass(), fqName, t);
				}
			}
		}
	}

}
