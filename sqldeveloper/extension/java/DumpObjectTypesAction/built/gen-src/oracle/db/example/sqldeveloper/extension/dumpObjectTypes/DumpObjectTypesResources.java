// Generated File. Do Not Modify
/*
Copyright (c) 2008,2017, Oracle and/or its affiliates. All rights reserved. 

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

import java.awt.Image;
import javax.swing.Icon;

import oracle.dbtools.raptor.utils.MessagesBase;

public class DumpObjectTypesResources extends MessagesBase {
    // Generated Resource Keys
    public static final String SHOW_OBJECT_TYPES_ACTION_LABEL = "SHOW_OBJECT_TYPES_ACTION_LABEL"; //$NON-NLS-1$
    public static final String DUMP_OBJECT_TYPES_ACTION_LABEL = "DUMP_OBJECT_TYPES_ACTION_LABEL"; //$NON-NLS-1$

    private static final String BUNDLE_NAME = "oracle.db.example.sqldeveloper.extension.dumpObjectTypes.DumpObjectTypesResources"; //$NON-NLS-1$

    private static final DumpObjectTypesResources INSTANCE = new DumpObjectTypesResources();
    
    private DumpObjectTypesResources() {
        super(BUNDLE_NAME, DumpObjectTypesResources.class.getClassLoader());
    }
    
//    public static ResourceBundle getBundle() {
//        return INSTANCE.getResourceBundle();
//    }
    
//    /**
//     * @deprecated use getBundle()
//     */
//   public static ResourceBundle getInstance() {
//        return getBundle();
 //   }
    
    public static String getString( String key ) {
        return INSTANCE.getStringImpl(key);
    }
    
    public static String get( String key ) {
        return getString(key);
    }
    
    public static Image getImage( String key ) {
        return INSTANCE.getImageImpl(key);
    }
    
    public static String format(String key, Object ... arguments) {
        return INSTANCE.formatImpl(key, arguments);
    }

    public static Icon getIcon(String key) {
        return INSTANCE.getIconImpl(key);
    }
    
    public static Integer getInteger(String key) {
        return INSTANCE.getIntegerImpl(key);
    }

}
