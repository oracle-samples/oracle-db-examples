# SQL Developer Examples
## Worksheet Action

Actions for the worksheet context menu and/or toolbar can be added via an ActionProvider registered in the extension.xml.

``` xml
<extension xmlns="http://jcp.org/jsr/198/extension-manifest" id="@@extension.id@@" version="@@extension.version@@.@@extension.build@@" esdk-version="1.0"
    . . .
    <hook>
        <sqldev-worksheet-hook xmlns="http://xmlns.oracle.com/sqldeveloper/sqldev-worksheet">
            <provider>my.great.MysteryActionProvider</provider>
        </sqldev-worksheet-hook>
    </hook>
</extension>        
```

``` java
package oracle.dbtools.worksheet;

import oracle.dbtools.worksheet.extension.WorksheetHook;

/**
 * The <code>ActionProvider</code> interface provides a mechanism for
 * registering actions in the Worksheet. Worksheet actions can be registered for
 * either the toolbar, the context menu, or both. Panels can be registered for
 * displaying the results of actions.
 * <p>
 * ActionProvider instances are responsible for determining the enabled state of
 * an action as well as creating Tasks to execute the action.
 * <p>
 * Registration occurs through the use of an extension hook.
 * <p>
 * 
 * @author jmcginni
 * @param <V>
 * @see WorksheetHook
 * 
 */
public interface ActionProvider<V> {
    /**
     * Returns the number of actions supported by this provider.
     * 
     * @return the number of supported actions
     */
    int getActionsCount();

    /**
     * Returns the action at the specified location.
     * 
     * @param i
     *            the index of the action
     * @return the WorksheetAction at the location
     * @throws IndexOutOfBoundsException
     *             if the specified location is out of range
     */
    WorksheetAction getActionAt(int i);

    /**
     * Returns the number of panels supported by this provider.
     * 
     * @return the number of supported panels
     */
    int getPanelCount();

    /**
     * Returns the panel at the specified location.
     * 
     * @param i
     *            the index of the panel
     * @return the WorksheetResultPanel at the location
     * @throws IndexOutOfBoundsException
     *             if the specified location is out of range
     */
    WorksheetResultPanel getPanelAt(int i);

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
    WorksheetTaskWrapper<V> doAction(String id, WorksheetContext ctx);

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
    boolean checkActionEnabled(String id, WorksheetContext ctx);
}

```



