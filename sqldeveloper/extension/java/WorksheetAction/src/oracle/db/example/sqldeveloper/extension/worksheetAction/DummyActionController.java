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

import oracle.ide.Context;
import oracle.ide.controller.Controller;
import oracle.ide.controller.IdeAction;

/**
 * DummyActionController - deploy as editor trigger action to force load the extension which has no natural trigger.
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.worksheetAction.DummyActionController">Brian Jeffries</a>
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
