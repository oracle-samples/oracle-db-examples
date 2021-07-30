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

import java.awt.BorderLayout;

import javax.swing.JMenuItem;
import javax.swing.JScrollPane;
import javax.swing.text.BadLocationException;
import javax.swing.text.Position;

import oracle.dbtools.util.Logger;
import oracle.dbtools.worksheet.WorksheetResultPanel;
import oracle.dbtools.worksheet.commands.autotrace.AbstractPanel;
import oracle.javatools.editor.BasicEditorPane;

/**
 * ExampleResultPanel - a really simple result panel just allowing text to be appended.
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.worksheetAction.ExampleResultPanel">Brian Jeffries</a>
 * @since SQL Developer 20.1
 */
public class ExampleResultPanel extends AbstractPanel {
    BasicEditorPane output = new BasicEditorPane();
    Position endPosition = output.getDocument().getEndPosition();

    /**
     * @param id
     * @param tabName
     */
    public ExampleResultPanel(String id, String tabName) {
        super(id, tabName);
        init();
    }

    private void init() {
        this.setLayout(new BorderLayout());
        JScrollPane scroll = new JScrollPane(output);
        scroll.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED);
        scroll.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
        this.add(scroll, BorderLayout.CENTER);
        initToolbar();
    }

    public void appendText(String text) {
        try {
            output.insertString(endPosition.getOffset(), text, null);
        } catch (BadLocationException e) {
            Logger.warn(getClass(), text, e);
        }
    }

    @Override
    public JMenuItem[] getTabDynamicCtxMenu(WorksheetResultPanel[] context) {
        /*
         * NOTE: This is used when, for example, you want to allow selection of, or navigation
         *       to, other result panels (compare execution plans) or you have special tab 
         *       context menu things that make sense for your result panel. Your panel can have
         *       its own toolbar / context menus so not generally used.
         */
        return null;
    }

}
