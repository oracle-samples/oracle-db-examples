/*
Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved. 

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

package oracle.db.example.sqldeveloper.extension.dependency.viewer;

import java.awt.BorderLayout;
import java.awt.Component;
import java.awt.Cursor;
import java.util.Collections;

import javafx.application.Platform;
import javafx.embed.swing.JFXPanel;
import javafx.scene.PerspectiveCamera;
import javafx.scene.Scene;

import javax.swing.JComponent;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.ScrollPaneConstants;
import javax.swing.SwingUtilities;

import oracle.dbtools.javafx.scene.SceneFactory;
import oracle.db.example.sqldeveloper.extension.dependency.DependencyExampleResources;
import oracle.db.example.sqldeveloper.extension.dependency.control.DependencyExampleFxControl;
import oracle.db.example.sqldeveloper.extension.dependency.model.DependencyExampleModel;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskAdapter;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskEvent;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskManager;
import oracle.dbtools.raptor.backgroundTask.TaskException;
import oracle.dbtools.raptor.backgroundTask.utils.DeferUIOperationTask;
import oracle.dbtools.raptor.editors.DbEditor; // So we get connection color border
import oracle.dbtools.raptor.editors.IStatusMessageProvider; // So our status message (if any) gets re-applied when switching editors
import oracle.dbtools.raptor.javafx.ui.JFXPanelFactory;
import oracle.dbtools.raptor.oviewer.base.ViewerNode;
import oracle.dbtools.raptor.utils.DBObject;
import oracle.dbtools.util.Logger;
import oracle.ide.Context;
import oracle.ide.Ide;
import oracle.ide.controls.WaitCursor;
import oracle.ide.editor.AsynchronousEditor;
import oracle.ide.editor.EditorManager;
import oracle.ide.model.UpdateMessage;

/**
 * DependencyExampleGraphViewer shows a dependency graph for the selected objects
 * 
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.dependency.viewer.DependencyExampleGraphViewer">Brian Jeffries</a>
 * @since SQL Developer 4.2
 */
public class DependencyExampleGraphViewer extends AsynchronousEditor implements DbEditor, IStatusMessageProvider {
    /*
     * Note that this gets re-used and the context information can be changed by a new one being sent in
     * AND ALSO by the context state being changed and an update message being sent. Since loadContentModel
     * is being triggered by all cases, that is where updating any context dependent variables will happen. 
     * NOTE: context updated and ViewSelectionChanged happens whenever selections are changed (the Views 
     *       check on a timer). We only care about what the selection is when we are called or the navigator
     *       framework changes the viewer node so we don't listen for ViewSelectionChanged.
     */
    private JComponent guiComponent;
    private JFXPanel fxPanel;
    private DependencyExampleFxControl dependencyExampleFxControl;
    
    private DependencyExampleModel dependencyModel; // context dependent
    private DBObject dbObject;                      // context dependent
    private boolean multipleSelections;             // context dependent

    /**
     * 
     */
    public DependencyExampleGraphViewer() {
        super(); // just for debug break
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.AsynchronousEditor#isContentModelLoaded()
     */
    @Override
    protected boolean isContentModelLoaded() {
        return dependencyModel != null && dependencyModel.isLoaded();
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.AsynchronousEditor#getGUIComponent()
     */
    @Override
    protected Component getGUIComponent() {
        // WE do not set up the load task, the framework does and will call 
        // getEditorContent off the UI thread to do the actual work
        return guiComponent;
        // When we return null, the framework will create the editor not 
        // initialized GUI which triggers the async load in it's paint method
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.AsynchronousEditor#getEditorContent(oracle.ide.Context)
     */
    @Override
    protected void getEditorContent(Context newContext) {
        try {
            if (null == getGUIComponent()) {
                createGUIComponent();
            }
        }
        catch (Exception e) {
            Logger.severe(getClass(), e);
        }
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.AsynchronousEditor#doSetContext(oracle.ide.Context)
     * Called when async UI build is done
     */
    @Override
    protected void doSetContext(Context context) {
        loadContentModel(context);
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.AsynchronousEditor#openImpl(boolean)
     * This is the very beginning, and happens when an editor is opened 
     * (e.g. [double] clicking a node in the Navigator.)
     */
    @Override
    protected void openImpl(boolean contentAvailable) {
    }

    /* (non-Javadoc)
     * @see oracle.dbtools.raptor.editors.IStatusMessageProvider#getStatusMessage()
     */
    @Override
    public String getStatusMessage() {
        // We have nothing to say but if we did, this would show up in the 
        // status bar when the editor is [re]activated
        return null;
    }

    /* (non-Javadoc)
     * @see oracle.dbtools.raptor.editors.DbEditor#getConnectionName()
     * This allows the connection color to be painted around the border
     */
    @Override
    public String getConnectionName() {
        return getDBObject() == null ? null : getDBObject().getConnectionName();
    }

    /**
     * @return a DBObject for the context's node
     */
    private DBObject getDBObject() {
        return dbObject;
    }

    private boolean initFxComplete;
    /**
     * 
     */
    private void createGUIComponent() {
        if (null == guiComponent) {
            try {
                // This method is invoked on the (Swing) event dispatch thread
                guiComponent = new JPanel(new BorderLayout());
                fxPanel = JFXPanelFactory.createJFXPanel();
                if (fxPanel != null) {
                    guiComponent.add(fxPanel, BorderLayout.CENTER);
                    
                    // NOTE: IMPORTANT: All operations on JavaFX components must 
                    // be done this way.
                    Platform.runLater(() -> {
                        try {
                            initFX(fxPanel);
                        }
                        finally {
                            initFxComplete = true;
                        }
                    });
                    // Can't return until initFx is done else UI isn't really ready
                    while (!initFxComplete) {
                        Thread.sleep(200);
                    }
                } else {
                    // Can't make fxPanel, close editor. TODO: Something nicer?
                    SwingUtilities.invokeLater(() -> {
                        EditorManager.getEditorManager().closeEditors(Collections.singletonList(DependencyExampleGraphViewer.this));                            
                    });
                }
            }
            catch (Exception e) {
                Logger.severe(getClass(), e);
            }
        }
    }

    /**
     * Create the FX UI and add to the panel
     * This is called from the FX Platform @see {@link #createGUIComponent()}
     * @param fxPanel the JFXPanel that will contain the UI
     */
    private void initFX(JFXPanel fxPanel) {
        try {
            dependencyExampleFxControl = new DependencyExampleFxControl();
            Scene scene = SceneFactory.createScene(dependencyExampleFxControl.getRoot());
            // GPU turned off in sqldev 18.1 scene.setCamera(new PerspectiveCamera());
            fxPanel.setScene(scene);
        }
        catch(Exception e) {
            Logger.severe(getClass(), e);
        }
    }

    /**
     * Update the editor state for a new/changed context
     * Note that from doSetContext, this may not match getContext(),
     * while from update it will.
     * @param context
     */
    private void loadContentModel(Context context) {
        if (dependencyModel != null) {
            if (!dependencyModel.checkSelectionsChanged(context)) {
                return;
            }
        }
        final WaitCursor waitCursor = new WaitCursor(Ide.getMainWindow());
        waitCursor.show();
        dbObject = new DBObject(context.getNode());
        multipleSelections = context.getSelection().length > 1;
        dependencyModel = new DependencyExampleModel(context);
        // Expensive tasks don't belong on the UI or FX threads. luckily we have a solution for that.
        final DeferUIOperationTask loadAndShowTask = 
                new DeferUIOperationTask(this.getClass().getSimpleName()+"-loadAndShowTask") { //$NON-NLS-1$
                    @Override
                    protected Object doWork() throws TaskException {
                        dependencyModel.load();
                        return null;
                    }

                    @Override
                    protected void invokeLater() {
                        // This is only called if the task finishes and is on the UI thread
                        dependencyExampleFxControl.setViewModel(dependencyModel, waitCursor);
                        // Force update UI
                        EditorManager.getEditorManager().refreshEditorUI(DependencyExampleGraphViewer.this);
                    }

                    @Override
                    public String getConnectionName() {
                        // The scheduler serializes on the connection so send
                        // real answer if you are making database queries.
                        return DependencyExampleGraphViewer.this.getConnectionName();
                    }
        };
        loadAndShowTask.getDescriptor().addListener(new RaptorTaskAdapter() {
            /* (non-Javadoc)
             * @see oracle.dbtools.raptor.backgroundTask.RaptorTaskAdapter#taskFailed(oracle.dbtools.raptor.backgroundTask.RaptorTaskEvent)
             */
            @Override
            public void taskFailed(RaptorTaskEvent event) {
                // TODO Add better failure action here. Exceptions should be in the 
                // log window already so this is more just a trivial example  
                SwingUtilities.invokeLater(() -> {
                    String message = String.valueOf(event.getThrowable());
                    String title = loadAndShowTask.getDescriptor().getName();
                    JOptionPane.showMessageDialog(Ide.getMainWindow(), message, title, JOptionPane.ERROR_MESSAGE);
                });
            }

            /* (non-Javadoc)
             * @see oracle.dbtools.raptor.backgroundTask.RaptorTaskAdapter#taskFinished(oracle.dbtools.raptor.backgroundTask.RaptorTaskEvent)
             */
            @Override
            public void taskFinished(RaptorTaskEvent event) {
                // The invoke later in the task gets called on taskFinished so we don't
                // really need anything here. TODO maybe log loading, loaded, or failed messages?
                super.taskFinished(event);
            }
        });
        RaptorTaskManager.getInstance().addTask(loadAndShowTask);
    }
    
    static boolean NO_SCROLL = true;
    /* (non-Javadoc)
     * @see oracle.ide.editor.Editor#getEditorAttribute(java.lang.String)
     * For this case, the FX control handles scrolling internally so the editor
     * framework should not. 
     */
    @Override
    public Object getEditorAttribute(String attribute) {
        if (NO_SCROLL) {
            if (ATTRIBUTE_HORIZONTAL_SCROLLBAR_POLICY.equals(attribute)) {
                return new Integer(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);
            } 
            else if (ATTRIBUTE_VERTICAL_SCROLLBAR_POLICY.equals(attribute)) {
                return new Integer(ScrollPaneConstants.VERTICAL_SCROLLBAR_NEVER);
            } 
            else if (ATTRIBUTE_SCROLLABLE.equals(attribute)) {
                return Boolean.FALSE;
            } 
        }
        return super.getEditorAttribute(attribute);
    }

    /* 
     * (non-Javadoc)
     * @see oracle.ide.editor.AsynchronousEditor#switchEditorGUI(java.awt.Component)
     */
    @Override
    protected void switchEditorGUI(Component newEditorGUI) {
        super.switchEditorGUI(newEditorGUI);
        // Is this still needed? YES
        EditorManager.getEditorManager().refreshEditorUI(this);
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.AsynchronousEditor#update(java.lang.Object, oracle.ide.model.UpdateMessage)
     */
    @Override
    public void update(Object observed, final UpdateMessage change) {
        if ( SwingUtilities.isEventDispatchThread() ) {
            updateImpl(change);
        } else {
            SwingUtilities.invokeLater( new Runnable() {
                public void run() {
                    updateImpl(change);
                }
            });
        }
    }

    private void updateImpl(UpdateMessage change) {
        final int messageID = change.getMessageID();
        if (ViewerNode.RELATION_NODE_CHANGED_MESSAGE_ID == messageID || 
                ViewerNode.RELATION_NODE_MODIFIED_MESSAGE_ID == messageID || 
                UpdateMessage.OBJECT_RELOADED == messageID) {
            loadContentModel(getContext());
        }
    }

    @Override
    public String getTabLabel() {
        if (multipleSelections) {
            return DependencyExampleResources.get(DependencyExampleResources.DEPENDENCY_VIEWER_LABEL);
        }
        return super.getTabLabel();
    }

    
}
