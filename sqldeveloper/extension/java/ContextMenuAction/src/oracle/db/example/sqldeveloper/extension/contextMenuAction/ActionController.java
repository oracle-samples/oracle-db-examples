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

package oracle.db.example.sqldeveloper.extension.contextMenuAction;

import java.sql.Connection;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;

import oracle.dbtools.db.DBUtil;
import oracle.dbtools.db.LockManager;
import oracle.dbtools.raptor.utils.DBObject;
import oracle.dbtools.util.Logger;
import oracle.ide.Context;
import oracle.ide.Ide;
import oracle.ide.controller.Controller;
import oracle.ide.controller.IdeAction;
import oracle.ide.view.View;
import oracle.javatools.editor.BasicEditorPane;
import oracle.javatools.editor.BasicEditorPaneContainer;
import oracle.javatools.editor.EditDescriptor;

/**
 * ActionController
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.contextMenuAction.ActionController">Brian Jeffries</a>
 * @since SQL Developer 4.2
 */

public class ActionController implements Controller {
    public static int ACTION_CMD = Ide.findOrCreateCmdID("Action_ID"); //$NON-NLS-1$
    @Override
    public boolean handleEvent( IdeAction action, Context context ) {
        int cmdId = action.getCommandId();
        if (ACTION_CMD == cmdId) {
            doAction(context);
            return true; // (I handled it)
        }
        return false; // Not my job, ask other controllers
    }
    @Override
    public boolean update(IdeAction action, Context context) {
//        int cmdId = action.getCommandId();
//        if (ACTION_CMD == cmdId) {
//            // If it is cheap and fast, figure out a real answer
//            // else just enable it and let handleEvent deal with
//            // it.
//            action.setEnabled(true);
//            return true; // (I handled it)
//        }
    	// Not our job, see rule declaration in extension.xml
        return false; // Not my job, ask other controllers
    }

    private void doAction(Context context) {
        final DBObject dbObject = new DBObject(context.getNode());
        final View view = context.getView();
        final BasicEditorPane editor = ((BasicEditorPaneContainer)view).getFocusedEditorPane();
        // this will insert at caret if there is no selection, else replace the selection
        editor.replaceSelection(ExtensionResources.format(ExtensionResources.ACTION_OUTPUT_FORMAT,
        		this.getClass().getSimpleName(), dbObject.getObjectType(), dbObject.getSchemaName(), dbObject.getObjectName()));
        
        // but lets say you need to ask the database something 1st ...
        // This should probably be in a background task (it talks to the database) like
        // DependencyExampleGraphViewer.loadContentModel does it but then we would need 
        // to deal with locking the plsql node (to avoid contending edits).  
        Connection conn = dbObject.getConnection();
        if (LockManager.lock(conn)) {
            try {
                DBUtil dbUtil = DBUtil.getInstance(conn);
                Map<String,String> binds = new HashMap<>();
                binds.put("NAME", dbObject.getObjectName()); //$NON-NLS-1$
                binds.put("OWNER", dbObject.getSchemaName()); //$NON-NLS-1$
                ResultSet rs = dbUtil.executeQuery(PLDOC_TEMPLATE_QUERY, binds);
                Throwable t = dbUtil.getLastException();
                if (t != null) {
                    throw t;
                }
                StringBuilder sb = new StringBuilder();
                while (rs.next()) {
                	sb.append(rs.getString("line")).append('\n');
                }
                if (sb.length() == 0) {
                	editor.replaceSelection("/* No information found. Was PL/Scope enabled when this was last compiled? */\n"); //TODO NLS
                } else {
                	editor.beginEdit(new EditDescriptor("Add PLDoc template")); //TODO NLS?
                	editor.replaceSelection(sb.toString());
                	editor.endEdit();
                }
            } catch (Throwable t) {
                Logger.warn(getClass(), t);
            } finally {
                LockManager.unlock(conn);
            }
        }
        
    }
    
    /*
     * With thanks to Joop Leendertse
     * Mildly edited to use binds in the initial subquery
     * Note that this only returns results if PL/Scope is active during function/procedure compilation
     */
    private static final String PLDOC_TEMPLATE_QUERY = 
    		"with\n" //$NON-NLS-1$
    		+"p as (\n" //$NON-NLS-1$
    		+"  select p.owner, p.object_name, p.object_type, p.usage_id, p.name\n" //$NON-NLS-1$
    		+"  from ALL_IDENTIFIERS p\n" //$NON-NLS-1$
    		+"  where p.usage = 'DEFINITION'\n" //$NON-NLS-1$
    		+"  and p.name = :NAME\n" //$NON-NLS-1$
    		+"  and p.owner = :OWNER\n" //$NON-NLS-1$
    		+"), lines as (\n" //$NON-NLS-1$
    		+"  -- first line\n" //$NON-NLS-1$
    		+"  select p.name, '/**' line, 1 s1, 1 s2 from p\n" //$NON-NLS-1$
    		+"union\n" //$NON-NLS-1$
    		+"  -- object description\n" //$NON-NLS-1$
    		+"  select p.name, ' * <object_descr>', 1 s1, 2 s2 from p\n" //$NON-NLS-1$
    		+"union\n" //$NON-NLS-1$
    		+"  -- empty line\n" //$NON-NLS-1$
    		+"  select p.name, ' *', 1 s1, 3 s2 from p\n" //$NON-NLS-1$
    		+"union\n" //$NON-NLS-1$
    		+"  select p.name, ' * @param ' || rpad(lower(param.name), 30) || ' : <param_descr>' , 2 s1, param.usage_id s2\n" //$NON-NLS-1$
    		+"  from p, ALL_IDENTIFIERS param\n" //$NON-NLS-1$
    		+"  where param.type like 'FORMAL %'\n" //$NON-NLS-1$
    		+"  and param.usage = 'DECLARATION'\n" //$NON-NLS-1$
    		+"  and p.usage_id = param.usage_context_id\n" //$NON-NLS-1$
    		+"  and p.object_name = param.object_name\n" //$NON-NLS-1$
    		+"  and p.object_type = param.object_type\n" //$NON-NLS-1$
    		+"union\n" //$NON-NLS-1$
    		+"  select p.name, ' * @return' || rpad(' ', 30) || ' : <return_descr>' , 3 s1, 1 s2\n" //$NON-NLS-1$
    		+"  from p\n" //$NON-NLS-1$
    		+"  where p.object_type = 'FUNCTION'\n" //$NON-NLS-1$
    		+"union\n" //$NON-NLS-1$
    		+"  -- last line\n" //$NON-NLS-1$
    		+"  select p.name, ' */', 4 s1, 1 s2 from p\n" //$NON-NLS-1$
    		+"  order by s1, s2\n" //$NON-NLS-1$
    		+") select line from lines\n" //$NON-NLS-1$
    		;
}
