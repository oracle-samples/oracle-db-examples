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

import static oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelperPreferenceModel.COMMAND_LINE_ACCEPT_CONN;
import static oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelperPreferenceModel.EXT_CONN_SVR_AUTOSTART;
import static oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelperPreferenceModel.EXT_CONN_SVR_PORT;

import oracle.ide.Addin;
import oracle.ide.Ide;
import oracle.ide.IdeEvent;
import oracle.ide.IdeListener;
import oracle.javatools.data.ChangeInfo;
import oracle.javatools.data.StructureChangeEvent;
import oracle.javatools.data.StructureChangeListener;

/**
 * ConnectionHelperAddin
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelperAddin">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ConnectionHelperAddin implements Addin {

	@Override
	public void initialize() {
		addIdeListener();
		addPreferenceListener();
	}

	@SuppressWarnings("deprecation")
	private void addIdeListener() {
		Ide.addIdeListener(new IdeListener() {

			@Override
			public void mainWindowOpened(IdeEvent e) {
				ConnectionHelperPreferenceModel model = ConnectionHelperPreferenceModel.getInstance();
				if (model.isAcceptCommandLineConnections()) {
					ConnectionHelper.processCommandLineArgs();
				}
				if (model.isAutostartExternalConnectionServer()) {
					ConnectionHelperServer.start();
				}
			}

			@Override
			public void addinsLoaded(IdeEvent e) {} // No longer fired see IdeEvent.IDE_ADDINS_LOADED
			@Override
			public void mainWindowClosing(IdeEvent e) {} // Don't care
		});
	}

	private void addPreferenceListener() {
		ConnectionHelperPreferenceModel.getInstance().addStructureChangeListener(new StructureChangeListener() {
			@Override
			public void structureValuesChanged(StructureChangeEvent e) {
				for (ChangeInfo change : e.getChangeDetails()) {
					switch(change.getPropertyName()) {
					case COMMAND_LINE_ACCEPT_CONN: 
						if (change.getNewValueAsBoolean()) {
							ConnectionHelper.processCommandLineArgs();
						}
						break;
					case EXT_CONN_SVR_AUTOSTART:
						if (change.getNewValueAsBoolean()) {
							ConnectionHelperServer.start();
						}
						break;
					case EXT_CONN_SVR_PORT:
						if (ConnectionHelperServer.isRunning()) {
							ConnectionHelperServer.stop();
							ConnectionHelperServer.start();
						}
						break;
					default: 
						break; // nothing 
					}
				}
			}
		});
	}

}
