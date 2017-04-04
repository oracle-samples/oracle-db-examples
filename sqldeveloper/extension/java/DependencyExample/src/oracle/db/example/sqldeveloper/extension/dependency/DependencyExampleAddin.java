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

package oracle.db.example.sqldeveloper.extension.dependency;

import oracle.db.example.sqldeveloper.extension.dependency.viewer.DependencyExampleGraphViewer;
import oracle.dbtools.raptor.navigator.impl.ObjectNode;
import oracle.ide.Context;
import oracle.ide.editor.EditorAddin;
import oracle.ide.editor.EditorManager;
import oracle.ide.model.Element;
import oracle.ide.util.MenuSpec;

/**
 * DependencyExampleAddin - an EditorAddin so we can use DependencyExampleGraphViewer 
 *                          outside the XML based reference (specifically to deal
 *                          with multiple objects selected)
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.dependency.DependencyExampleAddin">Brian Jeffries</a>
 * @since SQL Developer 4.2
 */
public class DependencyExampleAddin extends EditorAddin {
    /* (non-Javadoc)
     * @see oracle.ide.Addin#initialize()
     */
    @Override
    public void initialize() {
        // This class is too broad? and need to include PlSqlNode but not until
        // we refactor with an [R?]DockableWindow for the non objectviewer usage
        // see more comments in the controller
        Class<?>[] types = new Class[] { ObjectNode.class };
        EditorManager.getEditorManager().register(this, types);
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.EditorAddin#getEditorClass()
     */
    @Override
    public Class getEditorClass() {
        // TODO Auto-generated method stub
        return DependencyExampleGraphViewer.class;
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.EditorAddin#getMenuSpecification()
     */
    @Override
    public MenuSpec getMenuSpecification() {
        // TODO Auto-generated method stub
        return null;
    }


    /* (non-Javadoc)
     * @see oracle.ide.editor.EditorAddin#getEditorWeight(oracle.ide.model.Element, oracle.ide.Context)
     */
    @Override
    public float getEditorWeight(Element element, Context context) {
        return -0.5f;
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.EditorAddin#isDuplicable()
     */
    @Override
    public boolean isDuplicable() {
        return false;
    }

    /* (non-Javadoc)
     * @see oracle.ide.editor.EditorAddin#restoreAtStartup()
     */
    @Override
    public boolean restoreAtStartup() {
        return false;
    }
    
    
}
