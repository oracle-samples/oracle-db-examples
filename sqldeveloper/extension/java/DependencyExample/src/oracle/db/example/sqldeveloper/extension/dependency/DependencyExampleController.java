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

package oracle.db.example.sqldeveloper.extension.dependency;

import java.util.ArrayList;

import javax.swing.JOptionPane;

import oracle.db.example.sqldeveloper.extension.dependency.viewer.DependencyExampleGraphViewer;
import oracle.dbtools.util.Logger;
import oracle.ide.Context;
import oracle.ide.Ide;
import oracle.ide.controller.Controller;
import oracle.ide.controller.IdeAction;
import oracle.ide.controls.WaitCursor;
import oracle.ide.db.model.DBObjectTypeNode;
import oracle.ide.editor.Editor;
import oracle.ide.editor.EditorManager;
import oracle.ide.editor.OpenEditorOptions;
import oracle.ide.model.Element;

/**
 * DependencyExampleController
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.dependency.DependencyExampleController">Brian Jeffries</a>
 * @since SQL Developer 4.2
 */

public class DependencyExampleController implements Controller {
    public static final String SHOW_VIEWER_CMD = "DependencyExample.SHOW_VIEWER";
    static final int SHOW_VIEWER_ID = Ide.findOrCreateCmdID(SHOW_VIEWER_CMD);

    /* (non-Javadoc)
     * @see oracle.ide.controller.Controller#handleEvent(oracle.ide.controller.IdeAction, oracle.ide.Context)
     */
    @Override
    public boolean handleEvent(IdeAction action, Context context) {
        // This controller is for a single action, but just to show how to if it was not,
        if (SHOW_VIEWER_ID == action.getCommandId()) {
            try {
                if (null == openEditor(context)) {
                    Logger.warn(getClass(), "Editor is null!???");
                    oops(context);
                }
            } catch (Throwable t) {
                Logger.warn(getClass(), "Couldn't open editor", t);
                oops(context);
            }
            return true;
        } else {
            return false;
        }
    }

    /**
     * @param context
     */
    @SuppressWarnings("rawtypes")
    private void oops(Context context) {
        String msgFmt = "This will open a graphical dependency viewer for\n\n%s\n\nsomeday..."; //$NON-NLS-1$
        Element[] selection = context.getSelection();
        ArrayList<String> names = new ArrayList<>();
        for (Element element : selection) {
            // Same test in DependencyExampleModel.load
            if (element instanceof DBObjectTypeNode) {
                DBObjectTypeNode node = (DBObjectTypeNode)element;
                names.add(node.getSchemaName()+":"+node.getObjectType()+":"+node.getShortLabel());
            } else {
                names.add("NOT ObjectNode!! -> "+element.getLongLabel()); //$NON-NLS-1$
            }
        }
        String msg = String.format(msgFmt, String.valueOf(names));
        JOptionPane.showMessageDialog(Ide.getMainWindow(),msg);
    }

    /**
     * @param context
     */
    private Editor openEditor(Context context) {
        final OpenEditorOptions openEditorOptions = new OpenEditorOptions(context, DependencyExampleGraphViewer.class);
        openEditorOptions.setFlags(OpenEditorOptions.FOCUS);
        final EditorManager editorManager = EditorManager.getEditorManager();
        final WaitCursor waitCursor = new WaitCursor(Ide.getMainWindow());
        Editor editor = null; // just in case you needed it for something ...
        try {
            waitCursor.show();
            editor = editorManager.openEditor(openEditorOptions);
        }
        finally {
            waitCursor.hide();
        }
        String msg = String.format("Editor opened: %s", String.valueOf(editor));
        Logger.info(getClass(), msg);
        return editor;
    }

    /* (non-Javadoc)
     * @see oracle.ide.controller.Controller#update(oracle.ide.controller.IdeAction, oracle.ide.Context)
     */
    @Override
    public boolean update(IdeAction action, Context context) {
        return true;
    }

}
