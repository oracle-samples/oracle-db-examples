// Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.

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
			}

			@Override
			public void addinsLoaded(IdeEvent e) {} // No longer fired see IdeEvent.IDE_ADDINS_LOADED
			@Override
			public void mainWindowClosing(IdeEvent e) {} // Don't care
		});
	}
}
