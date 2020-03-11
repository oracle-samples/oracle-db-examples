// Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.

package oracle.db.example.sqldeveloper.extension.connectionHelper;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import oracle.dbtools.raptor.standalone.connection.ConnectionUtils;
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

	private static boolean processedCommandLineArgs;
	
	public static void processCommandLineArgs() {
//		if (!processedCommandLineArgs) {
	        String[] args = Ide.getIdeArgs().getArgs();
	        for (String arg : args) {
	        	System.out.println(arg);
	        	ConnectionHelper.processPotentialConnectionArgument(arg);
	        }
	        processedCommandLineArgs = true;
//		}
	}

	// -system_DB120101=system/dbtools@llg00hon.uk.oracle.com:1521/DB12201
    // -sysdba_DB120101=sys/dbtools@llg00hon.uk.oracle.com:1521/DB12201#SYSDBA
    // TODO? Look up valid character requirements for each group
    // format = -conName=user[/[pw]]@host:port(:sid|/svc)[#role]
    //           1       2      4    5    6     8    9     11
    private static final String conRegex = "-(.*)=([^\\/]*)(\\/([^@]*))?@([^:]*):([^:]*)(:([a-zA-Z0-9_]*)|\\/([a-zA-Z0-9_]*))(#([a-zA-Z0-9_]*))?"; //$NON-NLS-1$
    private static final Pattern conArg = Pattern.compile(conRegex);
	public static void processPotentialConnectionArgument(String arg) {
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
            String folder = ConnectionHelperPreferenceModel.getInstance().isPersistCommandLineConnections()
            		        ? ConnectionHelperResources.getString(ConnectionHelperResources.PERSISTENT)
            		        : ConnectionHelperResources.getString(ConnectionHelperResources.TRANSIENT);		
            
            
            ConnectionUtils.addConnection(connName, userName, password, sid, host, port, false/*osAuth*/, service, role, folder);
            final String fqName = ConnectionUtils.getFqConnectionName(connName);
            ConnectionUtils.connect(fqName);
            
            if (!ConnectionHelperPreferenceModel.getInstance().isPersistCommandLineConnections()) {
	            ExitCommand.addShutdownHook(new ShutdownHook() {
	                @Override
	                public boolean canShutdown() {
	                    return true;
	                }
	                @Override
	                public void shutdown() {
	                    ConnectionUtils.closeAndDeleteConnection(fqName);
	                }
	            });
            }
        }
	}
	
	// TODO Refactor to handle request from server
	public static void processPotentialConnectionRequest(String arg) {
		
	}

}
