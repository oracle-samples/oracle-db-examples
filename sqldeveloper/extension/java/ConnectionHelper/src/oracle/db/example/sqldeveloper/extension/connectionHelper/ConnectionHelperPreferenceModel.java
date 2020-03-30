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

import oracle.ide.config.Preferences;
import oracle.javatools.data.HashStructure;
import oracle.javatools.data.HashStructureAdapter;
import oracle.javatools.data.PropertyStorage;

/**
 * ConnectionHelperPreferenceModel
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelperPreferenceModel">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ConnectionHelperPreferenceModel extends HashStructureAdapter {

	private static final String DATA_KEY = ConnectionHelperPreferenceModel.class.getName();
	
	private static final String COMMAND_LINE_ACCEPT_CONN = "COMMAND_LINE_ACCEPT_CONN"; //$NON-NLS-1$
	private static final String COMMAND_LINE_PERSIST_CONN = "COMMAND_LINE_PERSIST_CONN"; //$NON-NLS-1$
	
	private static final String EXT_CONN_SVR_PORT = "EXT_CONN_SVR_PORT"; //$NON-NLS-1$
	private static final Integer EXT_CONN_SVR_DEFAULT_PORT = 51521; // 49152-65535 https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?search=1&page=24
	private static final String EXT_CONN_SVR_AUTOSTART = "EXT_CONN_SVR_AUTOSTART"; //$NON-NLS-1$
	private static final String EXT_CONN_SVR_PERSIST_CONN = "EXT_CONN_SVR_PERSIST_CONN"; //$NON-NLS-1$

	private ConnectionHelperPreferenceModel(HashStructure hash) {
		super(hash);
	}
	
	/**
	 * @return a ConnectionHelperPreferenceModel backed by the system Preferences
	 */
	public static ConnectionHelperPreferenceModel getInstance() {
		return getInstance(Preferences.getPreferences());
	}
	
	/**
	 * This one is used by the preference panel as it is running on a copy of the system 
	 * preferences to support OK/Cancel.<p/>
	 * @param prefs - PropertyStorage for the ConnectionHelperPreferenceModel
	 * @return a ConnectionHelperPreferenceModel backed by the supplied PropertyStorage
	 */
	/*package*/ static ConnectionHelperPreferenceModel getInstance(final PropertyStorage prefs) {
		return new ConnectionHelperPreferenceModel(HashStructureAdapter.findOrCreate(prefs, ConnectionHelperPreferenceModel.DATA_KEY));
	}

	/**
	 * @return the acceptCommandLineConnections
	 */
	public boolean isAcceptCommandLineConnections() {
		return getHashStructure().getBoolean(COMMAND_LINE_ACCEPT_CONN, false);
	}

	/**
	 * @param acceptCommandLineConnections the acceptCommandLineConnections to set
	 */
	public void setAcceptCommandLineConnections(boolean acceptCommandLineConnections) {
		getHashStructure().putBoolean(COMMAND_LINE_ACCEPT_CONN, acceptCommandLineConnections);
	}

	/**
	 * @return the persistCommandLineConnections
	 */
	public boolean isPersistCommandLineConnections() {
		return getHashStructure().getBoolean(COMMAND_LINE_PERSIST_CONN);
	}

	/**
	 * @param persistCommandLineConnections the persistCommandLineConnections to set
	 */
	public void setPersistCommandLineConnections(boolean persistCommandLineConnections) {
		getHashStructure().putBoolean(COMMAND_LINE_PERSIST_CONN, persistCommandLineConnections);
	}

	/**
	 * @return the externalConnectionServerPort
	 */
	public Integer getExternalConnectionServerPort() {
		return getHashStructure().getInt(EXT_CONN_SVR_PORT, EXT_CONN_SVR_DEFAULT_PORT);
	}

	/**
	 * @param externalConnectionServerPort the externalConnectionServerPort to set
	 */
	public void setExternalConnectionServerPort(Integer externalConnectionServerPort) {
		getHashStructure().putInt(EXT_CONN_SVR_PORT, externalConnectionServerPort);
	}

	/**
	 * @return the autostartExternalConnectionServer
	 */
	public boolean isAutostartExternalConnectionServer() {
		return getHashStructure().getBoolean(EXT_CONN_SVR_AUTOSTART, false);
	}

	/**
	 * @param autostartExternalConnectionServer the autostartExternalConnectionServer to set
	 */
	public void setAutostartExternalConnectionServer(boolean autostartExternalConnectionServer) {
		getHashStructure().putBoolean(EXT_CONN_SVR_AUTOSTART, autostartExternalConnectionServer);
	}

	/**
	 * @return the persistExternalConnectionServerConnections
	 */
	public boolean isPersistExternalConnectionServerConnections() {
		return getHashStructure().getBoolean(EXT_CONN_SVR_PERSIST_CONN, false);
	}

	/**
	 * @param persistExternalConnectionServerConnections the persistExternalConnectionServerConnections to set
	 */
	public void setPersistExternalConnectionServerConnections(boolean persistExternalConnectionServerConnections) {
		getHashStructure().putBoolean(EXT_CONN_SVR_PERSIST_CONN, persistExternalConnectionServerConnections);
	}
	
}
