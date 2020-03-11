// Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.

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
		
		// Add action listeners for the enable check boxes
		clAcceptConn.addActionListener(e -> {
			if (clAcceptConn.isSelected()) {
				ConnectionHelper.processCommandLineArgs();
			}
		});
		
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
		
		// TODO TEMP until svr built
		svrAutostart.setEnabled(false);
		svrPort.setEnabled(false);
		svrPersistConn.setEnabled(false);
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
