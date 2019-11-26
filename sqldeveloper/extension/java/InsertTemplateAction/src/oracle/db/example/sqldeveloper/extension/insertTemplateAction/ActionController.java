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

package oracle.db.example.sqldeveloper.extension.insertTemplateAction;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import oracle.ide.Context;
import oracle.ide.Ide;
import oracle.ide.controller.Controller;
import oracle.ide.controller.IdeAction;
import oracle.ide.view.View;
import oracle.javatools.editor.BasicEditorPane;
import oracle.javatools.editor.BasicEditorPaneContainer;

/**
 * ActionController
 *
 * @author <a href=
 *         "mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.insertTemplateAction.ActionController">Brian
 *         Jeffries</a>
 * @since SQL Developer 19.3
 */

public class ActionController implements Controller {
	public static int ACTION_CMD = Ide.findOrCreateCmdID("InsertTemplateAction_ID"); //$NON-NLS-1$

	@Override
	public boolean handleEvent(IdeAction action, Context context) {
		int cmdId = action.getCommandId();
		if (ACTION_CMD == cmdId) {
			doAction(context);
			return true; // (I handled it)
		}
		return false; // Not my job, ask other controllers
	}

	@Override
	public boolean update(IdeAction action, Context context) {
		int cmdId = action.getCommandId();
		if (ACTION_CMD == cmdId) {
			// If it is cheap and fast, figure out a real answer
			// else just enable it and let handleEvent deal with
			// it.
			action.setEnabled(true);
			return true; // required for trigger hook actions
		}
		return false; // Not my job, ask other controllers
	}

	private void doAction(Context context) {
		final View view = context.getView();
		final BasicEditorPane editor = ((BasicEditorPaneContainer) view).getFocusedEditorPane();

		loadMacros();
		String templateText = getTemplateText();
		String outputText = processMacros(templateText);

		// this will insert at caret if there is no selection, else replace the
		// selection
		editor.replaceSelection(outputText);

	}

	private String getTemplateText() {
		// TODO: get from file
		return "-- insertTemplateText Example\n-- @@USER@@@@@HOSTNAME@@ @@DATE@@\n";
	}

	private Map<String, String> macroMap = new HashMap<>();

	private void loadMacros() {
		// Some may be time sensitive so always reload
		//System.out.println(String.valueOf(System.getenv()).replace(",", ",\n"));
		//System.out.println(String.valueOf(System.getProperties()).replace(",", ",\n"));
		macroMap.clear();
		macroMap.put("@@USER@@", System.getenv("USERNAME"));
		macroMap.put("@@HOSTNAME@@", System.getenv("HOSTNAME"));
		macroMap.put("@@DATE@@", LocalDateTime.now().toString());
		return;
	}

	private String processMacros(String in) {
		if (null == in || in.isEmpty()) {
			return in;
		}
		String out = in;
		for (String macro : macroMap.keySet()) {
			String replacement = macroMap.get(macro);
			if (replacement != null && !replacement.isEmpty()) {
				out = out.replace(macro, replacement);
			}
		}
		return out;
	}

}
