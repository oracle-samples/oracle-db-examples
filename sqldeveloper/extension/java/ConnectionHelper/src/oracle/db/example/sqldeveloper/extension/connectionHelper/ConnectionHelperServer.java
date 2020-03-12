// Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.

package oracle.db.example.sqldeveloper.extension.connectionHelper;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.Socket;

import oracle.dbtools.raptor.backgroundTask.IRaptorTaskRunMode;
import oracle.dbtools.raptor.backgroundTask.RaptorTask;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskManager;
import oracle.dbtools.raptor.backgroundTask.TaskException;
import oracle.dbtools.raptor.backgroundTask.utils.DatabaseQueryTask;

/**
 * ConnectionHelperServer - a simple server to listen for connection requests
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelperServer">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ConnectionHelperServer {
	private static ServerTask serverTask;
	private static boolean listening;
	
	private static final String NAME_TEMPLATE = "%s-%d"; //$NON-NLS-1$
	
	public static void start() {
		stop();
		int port = ConnectionHelperPreferenceModel.getInstance().getExternalConnectionServerPort();
		serverTask = new ServerTask(String.format(NAME_TEMPLATE, ConnectionHelperServer.class.getSimpleName(), port), port);
		listening = true;
		RaptorTaskManager.getInstance().addTask(serverTask);
	}
	
	public static void stop() {
		if (serverTask != null) {
			serverTask.requestCancel();
			serverTask = null;
		}
	}
	
	private static class ServerTask extends RaptorTask<Void> {
		private int port;

		public ServerTask(String name, int port) {
			super(name, true /*isInDeterminate*/, IRaptorTaskRunMode.TASKVIEWER /*mode*/);
			this.port = port;
		}

		@Override
		protected Void doWork() throws TaskException {
			try (ServerSocket serverSocket = new ServerSocket(port)) {
				while (listening) {
					checkCanProceed();
					ConnectionHelperTask helperTask = new ConnectionHelperTask(serverSocket.accept()); 
					RaptorTaskManager.getInstance().addTask(helperTask);
				}
			}
			catch (Throwable t) {
				throw asTaskException(t);
			}
			return null;
		}
	}
	
	private static class ConnectionHelperTask extends DatabaseQueryTask<Void> {
		private Socket socket;
		private static int idx;
		
		public ConnectionHelperTask(Socket socket) {
			super(String.format(NAME_TEMPLATE, ConnectionHelperTask.class.getSimpleName(), ++idx),
					IRaptorTaskRunMode.TASKVIEWER, false /*isPausable*/, false /*isCancellable*/);
			this.socket = socket;
		}

		@Override
		public String getConnectionName() {
			// We are cheating here. DatabaseQueryTasks are serialized on the ConnectionName
			// so this is a way to make sure ConnectionHelperTasks are done one at a time.
			return this.getClass().getName();
		}

		@Override
		public String getQuery() {
			// This will be shown on the bottom of the task UI
			return this.getDescriptor().getStatus().toString();
		}

		@Override
		protected Void doWork() throws TaskException {
			try (BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()))) {
				String inputLine;
				while ((inputLine = in.readLine()) != null) {
					ConnectionHelper.processPotentialConnectionRequest(inputLine);
				}
			}
			catch (Throwable t) {
				throw asTaskException(t);
			}
			return null;
		}
		
	}

	public static TaskException asTaskException(Throwable t) {
		if (t instanceof TaskException) {
			return (TaskException)t;
		} else {
			return new TaskException(t);
		}
	}

}
