// Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.

package oracle.db.example.sqldeveloper.extension.worksheetAction;

import java.util.Collections;
import java.util.List;

import oracle.dbtools.common.utils.ModelUtil;
import oracle.dbtools.raptor.backgroundTask.IRaptorTaskListener;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskAdapter;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskDescriptor;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskEvent;
import oracle.dbtools.raptor.backgroundTask.internal.IRaptorTaskUIListener;
import oracle.dbtools.util.Logger;
import oracle.dbtools.worksheet.ActionProvider;
import oracle.dbtools.worksheet.WorksheetAction;
import oracle.dbtools.worksheet.WorksheetContext;
import oracle.dbtools.worksheet.WorksheetResultPanel;
import oracle.dbtools.worksheet.WorksheetTaskWrapper;

/**
 * ExampleActionProvider
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=extension.ExampleActionProvider">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ExampleActionProvider implements ActionProvider<Void> {
    
    // Action ids from extension.xml so actions already exist
    private static final String ACTION_BOTH_ID = "WorksheetAction.BOTH";
    private static final String ACTION_CONTEXT_MENU_ONLY_ID = "WorksheetAction.CONTEXT_MENU_ONLY";
    private static final String ACTION_TOOLBAR_ONLY_ID = "WorksheetAction.TOOLBAR_ONLY";
    private static final int    ACTION_COUNT = 3;
    
    /**
     * Returns the number of actions supported by this provider.
     * 
     * @return the number of supported actions
     */
    public int getActionsCount() {
        return ACTION_COUNT;
    }

    /**
     * Returns the action at the specified location.
     * 
     * @param i
     *            the index of the action
     * @return the WorksheetAction at the location
     * @throws IndexOutOfBoundsException
     *             if the specified location is out of range
     */
    public WorksheetAction getActionAt(int i) {
        switch (i) {
            case 0:
                return WorksheetAction.createWorksheetAction(ACTION_BOTH_ID, WorksheetAction.ActionType.BOTH , WorksheetAction.SECTION_RUN, 0.0d);
            case 1:
                return WorksheetAction.createWorksheetAction(ACTION_CONTEXT_MENU_ONLY_ID, WorksheetAction.ActionType.CONTEXT_MENU_ONLY , WorksheetAction.SECTION_RUN, 0.0d);
            case 2:
                return WorksheetAction.createWorksheetAction(ACTION_TOOLBAR_ONLY_ID, WorksheetAction.ActionType.TOOLBAR_ONLY , WorksheetAction.SECTION_RUN, 0.0d);
            default:
                throw new IndexOutOfBoundsException();        
        }
    }

    /**
     * Returns the number of panels supported by this provider.
     * 
     * @return the number of supported panels
     */
    public int getPanelCount() {
        return 0; 
    }

    /**
     * Returns the panel at the specified location.
     * 
     * @param i
     *            the index of the panel
     * @return the WorksheetResultPanel at the location
     * @throws IndexOutOfBoundsException
     *             if the specified location is out of range
     */
    public WorksheetResultPanel getPanelAt(int i) {
        // TODO: Try to do example for at least one of them (the task based one?)
        // There are no examples of this being used internally so save for playtime or someone asks
        return null;
    }

    /**
     * Returns a task that can be used to execute the action.
     * 
     * @param id
     *            a String identifying the action to perform
     * @param ctx
     *            the WorksheetContext describing the current Worksheet
     *            environment
     * @return a RaptorTask that encapsulates the running of the action
     */
    public WorksheetTaskWrapper<Void> doAction(String id, WorksheetContext ctx) {
        /*
         * NOTE: If the action is quick (think e.g., format text) and 
         *       isn't something that requires a task in its own right (e.g., anything that talks to the database),
         *       you can do / invokeLater the action here and return null.
         */
        ExampleActionTask task = null;
        switch (id) {
            case ACTION_BOTH_ID:
                task = new ExampleActionTask(ExtensionResources.get(ExtensionResources.WORKSHEET_ACTION_BOTH), ctx.getConnectionName(), false);
                break;
            case ACTION_CONTEXT_MENU_ONLY_ID:
                String name = ExtensionResources.get(ExtensionResources.WORKSHEET_ACTION_CONTEXT_MENU_ONLY);
                task = new ExampleActionTask(name, name, true);
                break;
            case ACTION_TOOLBAR_ONLY_ID:
                task = new ExampleActionTask(ExtensionResources.get(ExtensionResources.WORKSHEET_ACTION_TOOLBAR_ONLY), ctx.getConnectionName(), false);
                break;
            default:
                task = null;
                break;
        }
        if (null == task) {
            return null;
        }
        return new WorksheetTaskWrapper<Void>(task, getTaskListenerList(), getTaskUIListenerList(), Collections.singletonList(ctx.getTaskViewer()), ctx);
    }

    private List<IRaptorTaskListener> getTaskListenerList() {
        IRaptorTaskListener listener = new RaptorTaskAdapter() {
            /*
             * Note: NOT guaranteed to be called on the UI Thread. 
             * Use SwingUtilities.invoke(Later|AndWait) as needed 
             */

            @Override
            public void taskCancelled(RaptorTaskEvent event) {
                logMethod(event, "taskCancelled");
            }

            @Override
            public void taskFailed(RaptorTaskEvent event) {
                logMethod(event, "taskFailed");
            }

            @Override
            public void taskFinished(RaptorTaskEvent event) {
                logMethod(event, "taskFinished");
            }

            @Override
            public void taskPaused(RaptorTaskEvent event) {
                logMethod(event, "taskPaused");
            }

            @Override
            public void taskRunning(RaptorTaskEvent event) {
                logMethod(event, "taskRunning");
            }

            @Override
            public void taskScheduled(RaptorTaskEvent event) {
                logMethod(event, "taskScheduled");
            }

            @Override
            public void messageChanged(RaptorTaskEvent event) {
                /*
                 * Note: These are listened for from the task UI framework. 
                 *       Not typically processed elsewhere but in this case
                 *       we want to see the log entries. 
                 */
                // Debounce potential non-update
                String oldVal = String.valueOf(event.getOldValue());
                String newVal = event.getTaskDescriptor().getMessage();
                if (ModelUtil.areDifferent(newVal, oldVal)) {
                    String msg = "messageChanged " + newVal;
                    logMethod(event, msg);
                }
            }

            @Override
            public void progressChanged(RaptorTaskEvent event) {
                /*
                 * Note: These are listened for from the task UI framework. 
                 *       Not typically processed elsewhere but in this case
                 *       we want to see the log entries. 
                 */
                // Debounce progressbar paint's (non) update from the UI ticking the timer via RaptorTaskDescriptor.makeProgress(0, true)
                // Ref: SimpleRaptorTaskUI$4.paint(SimpleRaptorTaskUI.java:332) [in getProgressBar()]
                String oldVal = String.valueOf(event.getOldValue());
                String newVal = String.valueOf(event.getTaskDescriptor().getProgress());
                if (ModelUtil.areDifferent(newVal, oldVal)) {
                    String msg = "progressChanged " + newVal;
                    logMethod(event, msg);
                }
            }
            
            private void logMethod(RaptorTaskEvent event, String method) {
                String msg = event.getTaskDescriptor().getName() + " " + method;
                Throwable t = event.getThrowable();
                if (t != null) {
                    Logger.severe(getClass(), msg, t);
                } else {
                    Logger.info(getClass(), msg);
                }
            }
        };
        return Collections.singletonList(listener);
    }

    private class RaptorTaskUIAdapter implements IRaptorTaskUIListener {
        @Override
        public void cancelClicked(RaptorTaskDescriptor desc) {
        }

        @Override
        public void pauseClicked(RaptorTaskDescriptor desc) {
        }

        @Override
        public void taskClicked(RaptorTaskDescriptor desc) {
        }
    }
    
    private List<IRaptorTaskUIListener> getTaskUIListenerList() {
        IRaptorTaskUIListener listener = new RaptorTaskUIAdapter() {

            @Override
            public void cancelClicked(RaptorTaskDescriptor desc) {
                logMethod(desc, "cancelClicked");
            }

            @Override
            public void pauseClicked(RaptorTaskDescriptor desc) {
                logMethod(desc, "pauseClicked");
            }

            @Override
            public void taskClicked(RaptorTaskDescriptor desc) {
                logMethod(desc, "taskClicked");
            }
            
            private void logMethod(RaptorTaskDescriptor desc, String method) {
                String msg = desc.getName() + " " + method;
                Logger.info(getClass(), msg);
            }
        };
        return Collections.singletonList(listener);
    }

    /**
     * Returns whether the specified action should be enabled based on the
     * specified context.
     * 
     * @param id
     *            a String identifying the action to perform
     * @param ctx
     *            the WorksheetContext describing the current Worksheet
     *            environment
     * @return whether the action should be enabled.
     */
    public boolean checkActionEnabled(String id, WorksheetContext ctx) {
        switch (id) {
            case ACTION_BOTH_ID:
                // For example, check whether we have a connection
                return ModelUtil.hasLength(ctx.getConnectionName());
            case ACTION_CONTEXT_MENU_ONLY_ID:
                // Always enabled - note you will be asked for a connection if there isn't one 
                // I didn't chase down who/why.
                return true;
            case ACTION_TOOLBAR_ONLY_ID:
                // Check if editor has text
                return ModelUtil.hasLength(ctx.getEditor().getText());
            default:
                return false;
        }
    }

}
