// Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.

package oracle.db.example.sqldeveloper.extension.worksheetAction;;

import oracle.ide.Context;
import oracle.ide.controller.Controller;
import oracle.ide.controller.IdeAction;

/**
 * DummyActionController - deploy as editor trigger action to force load the extension
 * which has no natural trigger.
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=extension.DummyActionController">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class DummyActionController implements Controller {

    @Override
    public boolean handleEvent(IdeAction action, Context ctx) {
        // Just for the side effect - no real action needed
        return true;
    }

    @Override
    public boolean update(IdeAction action, Context ctx) {
        // Trigger-hook - return true so deferred loading works - huh, try false
        return true;
    }

}
