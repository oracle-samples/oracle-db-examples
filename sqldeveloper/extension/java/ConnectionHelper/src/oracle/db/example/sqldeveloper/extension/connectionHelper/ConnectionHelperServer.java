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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;

import oracle.dbtools.raptor.backgroundTask.IRaptorTaskRunMode;
import oracle.dbtools.raptor.backgroundTask.RaptorTask;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskManager;
import oracle.dbtools.raptor.backgroundTask.TaskException;
import oracle.dbtools.raptor.backgroundTask.utils.DatabaseQueryTask;
import oracle.dbtools.util.Logger;

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
		if (!listening) {
			int port = ConnectionHelperPreferenceModel.getInstance().getExternalConnectionServerPort();
			serverTask = new ServerTask(String.format(NAME_TEMPLATE, ConnectionHelperServer.class.getSimpleName(), port), port);
			listening = true;
			RaptorTaskManager.getInstance().addTask(serverTask);
		}
	}
	
	public static void stop() {
		if (serverTask != null) {
			serverTask.requestCancel();
			serverTask = null;
		}
	}
	
	public static boolean isRunning() {
		return listening && null == serverTask;
	}
	
	private static class ServerTask extends RaptorTask<Void> {
		private int port;
		private ServerSocket socket; // reference for cancel()
		
		public ServerTask(String name, int port) {
			super(name, true /*isInDeterminate*/, IRaptorTaskRunMode.TASKVIEWER /*mode*/);
			this.port = port;
		}

		/* (non-Javadoc)
		 * @see oracle.dbtools.raptor.backgroundTask.RaptorTask#cancel()
		 */
		@Override
		public boolean cancel() {
			if (socket != null) {
				try {
					listening = false;
					serverTask = null;
					socket.close();
				} catch (IOException e) {
					Logger.ignore(getClass(), e);
				}
			}
			return super.cancel();
		}

		@Override
		protected Void doWork() throws TaskException {
			try (ServerSocket serverSocket = new ServerSocket(port)) {
				socket = serverSocket;
				while (listening) {
					checkCanProceed();
					this.setMessage("Waiting for connection");
					// accept() listens for a connection to be made to this socket and accepts it. 
					// The method blocks until a connection is made.
					ConnectionHelperTask helperTask = new ConnectionHelperTask(serverSocket.accept()); 
					this.setMessage("Initializing ConnectionHelperTask");
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
			// We are "cheating" here. DatabaseQueryTasks are serialized on the ConnectionName
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
			try (BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
				 PrintWriter out =	new PrintWriter(socket.getOutputStream(), true);) {
				String inputLine= in.readLine();
				try {
					ConnectionHelper.processPotentialConnectionRequest(inputLine);
					out.println("Request Submitted");
				}
				catch (Throwable t) {
					t.printStackTrace(out);
					throw asTaskException(t);
				}
			}
			catch (Throwable t) {
				throw asTaskException(t);
			}
			return null;
		}
		
	}

	private static TaskException asTaskException(Throwable t) {
		if (t instanceof TaskException) {
			return (TaskException)t;
		} else {
			return new TaskException(t);
		}
	}

}
