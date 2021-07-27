// Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved.

package oracle.db.example.sqldeveloper.extension.worksheetAction;

import oracle.dbtools.raptor.backgroundTask.IRaptorTaskRunMode;
import oracle.dbtools.raptor.backgroundTask.RaptorTaskDescriptor;
import oracle.dbtools.raptor.backgroundTask.TaskException;
import oracle.dbtools.raptor.backgroundTask.utils.DatabaseQueryTask;

/**
 * ExampleActionTask - a dummy task to show the basic mechanics
 * 
 * The importance of using a DatabaseQueryTask (or derivative) is that queued DatabaseQueryTasks
 * are synchronized on the connection name. 
 * This is both a technique for serializing requests to a specific connection name as well as
 * a way to serialize operations against an arbitrary string.
 * If there is a task ui, it will display waiting on task xyz when the scheduling rule blocks
 * immediate execution. 
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.worksheetAction.ExampleActionTask">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ExampleActionTask extends DatabaseQueryTask<Void> {
    private String connectionName;

    public ExampleActionTask(String name, String aConnectionName, boolean isIndeterminate) {
        super(name, IRaptorTaskRunMode.TASKVIEWER, true, true, isIndeterminate);
        connectionName = aConnectionName;
    }

    @Override
    public String getConnectionName() {
        return connectionName;
    }

    @Override
    public String getQuery() {
        // We are going to overwrite the message right away so look quick.
        // Typical use is when running query.
        return getClass().getSimpleName();
    }

    @Override
    protected Void doWork() throws TaskException {
        try {
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
                
                this.setMessage(descriptor.getName()+" - "+progress);
                if (!descriptor.isInDeterminate()) {
                    descriptor.setProgress(progress);
                }
                Thread.sleep(1000); // 1sec
                progress += 10;
            }
            if (!descriptor.isInDeterminate()) {
                descriptor.setProgress(progress);
            }
            
            // Once the task is removed, the worksheet (and AbstractWorksheetTaskResultPanel) 's 
            // swap out the taskUI for a label with the elapsed time. That is going to require thought
            // and internal updates to expose a way of formatting that message.
            // In the meantime, we can get close by pausing a few seconds after setting our desired message.
            // Better solution might be to create a custom task result panel if you have advanced monitoring
            // or reporting requirements. OR NOT - that will require internal changes as well - the task
            // viewer and listener are final - and hard coded for use.
            this.setMessage(descriptor.getName()+" - Complete. Lots of stuff done.");
            Thread.sleep(3000);
        }
        catch (Throwable t) {
            throw asTaskException(t);
        }
        return null;
    }

    private TaskException asTaskException(Throwable t) {
        if (t instanceof TaskException) {
            return (TaskException)t;
        } else {
            return new TaskException(t);
        }
    }

}
