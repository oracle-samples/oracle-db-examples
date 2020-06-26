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

import javax.swing.JCheckBox;
import javax.swing.JSpinner;

import oracle.dbtools.util.Logger;
import oracle.ide.controls.JNumericSpinBox;
import oracle.ide.panels.DefaultTraversablePanel;
import oracle.ide.panels.TraversableContext;
import oracle.ide.panels.TraversalException;
import oracle.javatools.ui.layout.FieldLayoutBuilder;

/**
 * ConnectionHelperPreferencePanel - The preference page for ConnectionHelper<p/>
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.connectionHelper.ConnectionHelperPreferencePanel">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
@SuppressWarnings("deprecation")
public class ConnectionHelperPreferencePanel extends DefaultTraversablePanel {

	private JCheckBox clAcceptConn = new JCheckBox();
	private JCheckBox clPersistConn = new JCheckBox();
	
	// see RFC 1700 (http://www.ietf.org/rfc/rfc1700.txt?number=1700)
	private JNumericSpinBox svrPort = new JNumericSpinBox(1024, 65535);
	private JCheckBox svrAutostart = new JCheckBox();
	private JCheckBox svrPersistConn = new JCheckBox();
	
	public ConnectionHelperPreferencePanel() {
		try {
			layoutControls();
		}
		catch (Throwable t) {
			Logger.warn(getClass(), t);
		}
	}
	
	private void layoutControls() {
		// Apply our preferred (no commas) format
		JSpinner.NumberEditor editor = new JSpinner.NumberEditor(svrPort, "###0"); //$NON-NLS-1$
		svrPort.setEditor(editor);
		
		// Add action listeners for the enable check boxes TODO: Add StructureChangeListener 
		// in Addin to watch these ... or ... add buttons to manually execute/start them?
		// The more I think about it, I like this better than buttons. Maybe better than 
		// the listener but the listener would also demonstrate how to listen for preference
		// changes.
//		clAcceptConn.addActionListener(e -> {
//			if (clAcceptConn.isSelected()) {
//				ConnectionHelper.processCommandLineArgs();
//			}
//		});
//		svrAutostart.addActionListener(e -> {
//			if (svrAutostart.isSelected()) {
//				ConnectionHelperServer.start();
//			}
//		});
		
		final FieldLayoutBuilder builder = new FieldLayoutBuilder(this);
		builder.setAlignLabelsLeft(true);
		builder.add(builder.field().label().withText(ConnectionHelperResources.getString(ConnectionHelperResources.COMMAND_LINE_ACCEPT_CONN))
				.component(clAcceptConn));
		builder.add(builder.indentedField().label().withText(ConnectionHelperResources.getString(ConnectionHelperResources.COMMAND_LINE_PERSIST_CONN))
				.component(clPersistConn));
		builder.addVerticalGap();
		builder.add(builder.field().label().withText(ConnectionHelperResources.getString(ConnectionHelperResources.EXT_CONN_SVR_AUTOSTART))
				.component(svrAutostart));
		builder.add(builder.indentedField().label().withText(ConnectionHelperResources.getString(ConnectionHelperResources.EXT_CONN_SVR_PORT))
				.component(svrPort));
		builder.add(builder.indentedField().label().withText(ConnectionHelperResources.getString(ConnectionHelperResources.EXT_CONN_SVR_PERSIST_CONN))
				.component(svrPersistConn));
		builder.addVerticalSpring();
	}

	/* (non-Javadoc)
	 * @see oracle.ide.panels.DefaultTraversablePanel#onEntry(oracle.ide.panels.TraversableContext)
	 */
	@Override
	public void onEntry(TraversableContext dataContext) {
		ConnectionHelperPreferenceModel model = getModel(dataContext);
		clAcceptConn.setSelected(model.isAcceptCommandLineConnections());
		clPersistConn.setSelected(model.isPersistCommandLineConnections());
		
		svrPort.setIntValue(model.getExternalConnectionServerPort());
		svrAutostart.setSelected(model.isAutostartExternalConnectionServer());
		svrPersistConn.setSelected(model.isPersistExternalConnectionServerConnections());
	}

	/* (non-Javadoc)
	 * @see oracle.ide.panels.DefaultTraversablePanel#onExit(oracle.ide.panels.TraversableContext)
	 */
	@Override
	public void onExit(TraversableContext dataContext) throws TraversalException {
		ConnectionHelperPreferenceModel model = getModel(dataContext);
		model.setAcceptCommandLineConnections(clAcceptConn.isSelected());
		model.setPersistCommandLineConnections(clPersistConn.isSelected());
		
		model.setExternalConnectionServerPort(svrPort.getIntValue());
		model.setAutostartExternalConnectionServer(svrAutostart.isSelected());
		model.setPersistExternalConnectionServerConnections(svrPersistConn.isSelected());
	}
	
	private ConnectionHelperPreferenceModel getModel(TraversableContext dataContext) {
		return ConnectionHelperPreferenceModel.getInstance(dataContext.getPropertyStorage());
	}
	
}
