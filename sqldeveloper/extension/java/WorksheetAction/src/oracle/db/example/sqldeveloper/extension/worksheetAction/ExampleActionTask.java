/*
 * Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

package oracle.db.example.sqldeveloper.extension.worksheetAction;

import javax.swing.SwingUtilities;

import oracle.dbtools.raptor.backgroundTask.IRaptorTaskRunMode;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskDescriptor;
import oracle.dbtools.raptor.backgroundTask.TaskException;
import oracle.dbtools.raptor.backgroundTask.utils.DatabaseQueryTask;
import oracle.dbtools.worksheet.WorksheetCallback;

/**
 * ExampleActionTask - a dummy task to show the basic mechanics
 * 
 * The importance of using a DatabaseQueryTask (or derivative) is that queued DatabaseQueryTasks are synchronized on the connection name. This is both a technique for serializing
 * requests to a specific connection name as well as a way to serialize operations against an arbitrary string. If there is a task ui, it will display waiting on task xyz when the
 * scheduling rule blocks immediate execution.
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.worksheetAction.ExampleActionTask">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ExampleActionTask extends DatabaseQueryTask<Void> {
    private String connectionName;
    private WorksheetCallback worksheetCallback;
    private ExampleResultPanel resultPanel;
    private String actionId;

    /**
     * Construct an ExampleActionTask without a WorksheetResultPanel
     * 
     * @param name
     *            - the task name
     * @param aConnectionName
     *            - the connectionName
     * @param isIndeterminate
     *            - if false, progress is expected to be set by this task
     */
    public ExampleActionTask(String name, String aConnectionName, boolean isIndeterminate) {
        this(name, aConnectionName, null, null, isIndeterminate);
    }

    /**
     * Construct an ExampleActionTask that has a WorksheetResultPanel OR needs to enable / disable the worksheet while running.
     * 
     * @param name
     *            - the task name
     * @param aConnectionName
     *            - the connectionName
     * @param callback
     *            - interface to manage worksheet & result panel
     * @param actionId
     *            - needed for resultPanel
     * @param isIndeterminate
     *            - if false, progress is expected to be set by this task
     */
    public ExampleActionTask(String name, String aConnectionName, WorksheetCallback callback, String actionId, boolean isIndeterminate) {
        super(name, IRaptorTaskRunMode.TASKVIEWER, true, true, isIndeterminate);
        connectionName = aConnectionName;
        worksheetCallback = callback;
        this.actionId = actionId;
        /*
         * Note: query / message is NOT displayed on the toolbar task viewer Consider a result panel if you need to log or present detailed information.
         */
        maybeSetUpResultPanel();
    }

    @Override
    public String getConnectionName() {
        return connectionName;
    }

    @Override
    public String getQuery() {
        // We are going to overwrite the message right away so look quick.
        // Typical use is when actually running a query. Displayed as "Running: "+ getQuery() 
        return getClass().getSimpleName();
    }

    @Override
    protected Void doWork() throws TaskException {
        try {

            // Demonstrate locking the worksheet while processing
            if (ExampleActionProvider.ACTION_TOOLBAR_ONLY_ID.equals(actionId)) {
                maybeSetWorksheetEnabled(false); // make sure to reset in catch block
            }

            // Pause a few seconds before starting to see where getQuery ends up on UI
            // (Same as / overwritten by message)
            Thread.sleep(3000);

            // Set up a ten second loop to demonstrate setting progress / status
            // as well as checking for cancel/pause
            int progress = 0;
            RaptorTaskDescriptor descriptor = this.getDescriptor();
            while (progress < 100) {
                // This is how to actually support pause/cancel:
                // At every point in your process that blocking this thread (pause) or
                // throwing an exception (cancel) is appropriate, call checkCanProceed.
                // It will block the thread if pause has been requested, throw a cancelled
                // exception if cancel has been requested, or simply return.
                // You can also do this programmatically if you have a reference to the task.
                // task.request(Cancel|Pause) can be called from anywhere, task.resume will
                // need to be called from a different thread since this one will block on pause.
                this.checkCanProceed();

                String msg = descriptor.getName() + " - " + progress;
                this.setMessage(msg);
                maybeUpdateResultPanel(msg + "\n");

                if (!descriptor.isInDeterminate()) {
                    descriptor.setProgress(progress);
                }

                Thread.sleep(1000); // 1sec
                progress += 10;
            }
            if (!descriptor.isInDeterminate()) {
                descriptor.setProgress(progress);
            }

            String msg = descriptor.getName() + " - Complete. Lots of stuff done.";
            this.setMessage(msg);
            maybeUpdateResultPanel(msg + "\n");

            Thread.sleep(3000);
        } catch (Throwable t) {
            throw asTaskException(t);
        } finally {
            // We are done, enable worksheet and focus on our resultPanel
            maybeSetWorksheetEnabled(true);
            maybeFocusResultPane();
        }
        return null;
    }

    private void maybeUpdateResultPanel(String msg) {
        if (resultPanel != null) {
            SwingUtilities.invokeLater(() -> resultPanel.appendText(msg));
        }
    }

    private void maybeSetUpResultPanel() {
        if (worksheetCallback != null) {
            resultPanel = new ExampleResultPanel(actionId, getDescriptor().getName());
            getDescriptor().addListener(resultPanel.new ResultsPanelTaskListener());
            SwingUtilities.invokeLater(() -> worksheetCallback.showResultPanel(resultPanel));
        }
    }

    private void maybeFocusResultPane() {
        if (worksheetCallback != null && resultPanel != null) {
            SwingUtilities.invokeLater(() -> worksheetCallback.focusPanel(resultPanel));
        }
    }

    private void maybeSetWorksheetEnabled(boolean enabled) {
        if (worksheetCallback != null) {
            SwingUtilities.invokeLater(() -> worksheetCallback.setEnabled(enabled));
        }
    }

    private TaskException asTaskException(Throwable t) {
        if (t instanceof TaskException) {
            return (TaskException) t;
        } else {
            return new TaskException(t);
        }
    }

}
