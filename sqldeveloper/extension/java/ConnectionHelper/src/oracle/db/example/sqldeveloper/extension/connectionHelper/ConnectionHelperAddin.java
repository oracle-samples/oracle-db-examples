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

import oracle.dbtools.util.Logger;
import oracle.ide.Addin;
import oracle.ide.Ide;
import oracle.ide.IdeEvent;
import oracle.ide.IdeListener;

/**
 * ConnectionHelperAddin
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelperAddin">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ConnectionHelperAddin implements Addin {

	/* (non-Javadoc)
	 * @see oracle.ide.Addin#initialize()
	 */
	@Override
	public void initialize() {
		Logger.info(getClass(), "Initialize"); // TODO REMOVE
		addIdeListener(); // Don't do any checking now, need system initialized first.
	}

	@SuppressWarnings("deprecation")
	private void addIdeListener() {
		Ide.addIdeListener(new IdeListener() {

			@Override
			public void mainWindowOpened(IdeEvent e) {
				if (ConnectionHelperPreferenceModel.getInstance().isAcceptCommandLineConnections()) {
					ConnectionHelper.processCommandLineArgs();
				}
				if (ConnectionHelperPreferenceModel.getInstance().isAutostartExternalConnectionServer()) {
					ConnectionHelperServer.start();
				}
			}

			@Override
			public void addinsLoaded(IdeEvent e) {} // No longer fired see IdeEvent.IDE_ADDINS_LOADED
			@Override
			public void mainWindowClosing(IdeEvent e) {} // Don't care
		});
	}
}
