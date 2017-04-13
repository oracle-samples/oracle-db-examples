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

package oracle.db.example.sqldeveloper.extension.dumpObjectTypes;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import javax.swing.JOptionPane;

import oracle.dbtools.raptor.backgroundTask.RaptorTaskManager;
import oracle.dbtools.raptor.backgroundTask.TaskException;
import oracle.dbtools.raptor.backgroundTask.utils.DeferUIOperationTask;
import oracle.dbtools.raptor.dialogs.actions.XMLBasedObjectAction;
import oracle.dbtools.raptor.navigator.db.model.ObjectType;
import oracle.dbtools.raptor.navigator.db.xml.NavigatorDescriptor;
import oracle.dbtools.raptor.navigator.db.xml.NavigatorHook;
import oracle.dbtools.raptor.oviewer.base.ViewerAddin;
import oracle.dbtools.raptor.utils.DBObject;
import oracle.dbtools.util.Logger;
import oracle.ide.AddinManager;
import oracle.ide.Context;
import oracle.ide.Ide;
import oracle.ide.controller.Controller;
import oracle.ide.controller.IdeAction;
import oracle.javatools.util.Pair;

/**
 * DumpObjectTypesController
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.dumpObjectTypesAction.DumpObjectTypesController">Brian Jeffries</a>
 * @since SQL Developer 4.2
 */

public class DumpObjectTypesController implements Controller {
    public static final String DUMP_OBJECT_TYPES_CMD = "DumpObjectTypes.DUMP";
    static final int DUMP_OBJECT_TYPES_ID = Ide.findOrCreateCmdID(DUMP_OBJECT_TYPES_CMD);
    public static final String SHOW_OBJECT_TYPES_CMD = "DumpObjectTypes.SHOW";
    static final int SHOW_OBJECT_TYPES_ID = Ide.findOrCreateCmdID(SHOW_OBJECT_TYPES_CMD);

    /* (non-Javadoc)
     * @see oracle.ide.controller.Controller#handleEvent(oracle.ide.controller.IdeAction, oracle.ide.Context)
     */
    @Override
    public boolean handleEvent(IdeAction action, Context context) {
        if (DUMP_OBJECT_TYPES_ID == action.getCommandId()) {
            dumpObjectTypes();
        }
        if (SHOW_OBJECT_TYPES_ID == action.getCommandId()) {
            showObjectTypes(context);
        }
        return true;
    }

    private void showObjectTypes(Context context) {
        String msg = null;
        try {
            DBObject dbObject = new DBObject(context.getNode());
            msg = dbObject.getKey()+"\n"+dbObject.getElement().getClass().getName();
        }
        catch (Throwable t) {
            msg = t.getMessage();
            Logger.warn(getClass(), t);
        }
        JOptionPane.showMessageDialog(Ide.getMainWindow(),msg);
    }

    private void dumpObjectTypes() {
        // Lets see, I guess alpha objType (connType...)
        final Map<String,List<String>> objectTypeMap = new TreeMap<>();
        final DeferUIOperationTask dumpObjectTypesTask = 
                new DeferUIOperationTask(this.getClass().getSimpleName()+"-dumpObjectTypesTask") {
                    @Override
                    protected Object doWork() throws TaskException {
                        // There's no one source of truth so find all the types that have
                        // actions, navigators, or viewers defined on them.
                        // *)!&$~)% gonna have to cheat for actions ...
                        try {
                            java.lang.reflect.Field field = XMLBasedObjectAction.class.getDeclaredField("m_actionMap");
                            if (field != null) {
                                java.security.AccessController.doPrivileged(new java.security.PrivilegedAction<Void>() {
                                    public Void run() {
                                        field.setAccessible(true);
                                        return null;
                                    }
                                });
                                Map<Object, Object> actionMap = (Map<Object, Object>) field.get(XMLBasedObjectAction.getInstance());
                                for (Object typeKey : actionMap.keySet()) {
                                    addIfNew(objectTypeMap, String.valueOf(typeKey));
                                }
                            }
                        }
                        catch (Throwable t) {
                            Logger.warn(getClass(), "Unable to query XMLBasedObjectActions", t);
                            throw asTaskException(t);
                        }
                        for (Iterator<NavigatorDescriptor> iter = NavigatorHook.getHookInstance(NavigatorHook.DB_NAV_TYPE).getNavigatorDescriptors(); iter.hasNext();) {
                            NavigatorDescriptor desc = iter.next();
                            for (Pair<String, ObjectType> obj : desc.getObjectTypes()) {
                                String connType = obj.getSecond().getDBType();
                                String objType = obj.getSecond().getType();
                                String typeKey = connType+"#"+objType;
                                addIfNew(objectTypeMap, typeKey);
                            }
                        }
                        ViewerAddin viewerAddin = AddinManager.getAddinManager().getAddin(ViewerAddin.class);
                        for (String typeKey : viewerAddin.getXMLEditors().keySet()) {
                            addIfNew(objectTypeMap, typeKey);
                        }
                        return null;
                    }

                    @Override
                    protected void invokeLater() {
                        // OK, tree map so alpha sort already on key
                        String dump = String.valueOf(objectTypeMap);
                        // Transform from valueOf to nice list fit for .md
                        dump = dump.replaceFirst("\\{",  "* ");
                        dump = dump.replaceAll("=", " ");
                        dump = dump.replaceAll("\\], ", "]\n* ");
                        dump = dump.replaceFirst("\\}", "");
                        // aaaand since .md treats underscores as special,
                        dump = dump.replaceAll("\\_", "\\\\_");
                        Logger.info(getClass(), dump);
                    }

                    @Override
                    public String getConnectionName() {
                        // Not using a connection so return null
                        return null;
                    }
                };
        RaptorTaskManager.getInstance().addTask(dumpObjectTypesTask);
        
    }

    protected TaskException asTaskException(Throwable t) {
        if (t instanceof TaskException) {
            return (TaskException)t;
        }
        return new TaskException(t);
    }

    private void addIfNew(Map<String, List<String>> objectTypeMap, String typeKey) {
        String[] connThenType = typeKey.split("#");
        String connType = "null".equals(connThenType[0]) ? "Oracle" : connThenType[0];
        String objType = connThenType[1];
        List<String> conns = objectTypeMap.get(objType);
        if (null == conns) {
            conns = new ArrayList<>();
        }
        if (!conns.contains(connType)) {
            conns.add(connType);
        }
        Collections.sort(conns); // cheaper to do this as a post-process but it's not like
                                 // this is going to get used often.
        objectTypeMap.put(objType, conns);
    }

    /* (non-Javadoc)
     * @see oracle.ide.controller.Controller#update(oracle.ide.controller.IdeAction, oracle.ide.Context)
     */
    @Override
    public boolean update(IdeAction arg0, Context arg1) {
        return true;
    }

}
