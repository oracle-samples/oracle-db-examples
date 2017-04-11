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

package oracle.db.example.sqldeveloper.extension.dependency.model;

import java.sql.Connection;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import oracle.dbtools.db.DBUtil;
import oracle.dbtools.db.LockManager;
import oracle.dbtools.raptor.controls.celleditor.drilllinks.DrillLinkRegistry;
import oracle.dbtools.raptor.controls.grid.IDrillLink;
import oracle.dbtools.raptor.oviewer.base.ViewerNode;
import oracle.dbtools.raptor.utils.DBObject;
import oracle.dbtools.util.Logger;
import oracle.ide.Context;
import oracle.ide.db.model.DBObjectTypeNode;
import oracle.ide.model.Element;

/**
 * DependencyExampleModel
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.dependency.model.DependencyExampleModel">Brian Jeffries</a>
 * @since SQL Developer 4.2
 */

public class DependencyExampleModel {

    private static final String DEPENDENCY_QUERY2 = 
            "select owner, name, type, referenced_owner, referenced_name, referenced_type\n" //$NON-NLS-1$
           +"  from all_dependencies\n"                                                      //$NON-NLS-1$
           +" where (owner,name,type) in (%s)\n"                                             //$NON-NLS-1$
           +"   and referenced_owner != 'SYS' and referenced_name != 'DUAL'\n"               //$NON-NLS-1$
           +"UNION\n"                                                                        //$NON-NLS-1$ 
           +"select owner, name, type, referenced_owner, referenced_name, referenced_type\n" //$NON-NLS-1$
           +"  from all_dependencies\n"                                                      //$NON-NLS-1$
           +" where (referenced_owner,referenced_name,referenced_type) in (%s)\n"            //$NON-NLS-1$
           +"\n" //$NON-NLS-1$
           ;
    // OK, so indexes officially reference columns but we really want the table relationship
    private static final String DEPENDENCY_QUERY4 = 
            "WITH index_dependencies AS (\n"                                                 //$NON-NLS-1$
           +"    select owner, index_name name, 'INDEX' type, table_owner referenced_owner," //$NON-NLS-1$
           +"           table_name referenced_name, table_type referenced_type\n"            //$NON-NLS-1$
           +"      from all_indexes\n"                                                       //$NON-NLS-1$
           +")\n"                                                                            //$NON-NLS-1$
           +"select owner, name, type, referenced_owner, referenced_name, referenced_type\n" //$NON-NLS-1$
           +"  from index_dependencies\n"                                                    //$NON-NLS-1$
           +" where (owner,name,type) in (%s)\n"                                             //$NON-NLS-1$
           +"   and referenced_owner != 'SYS' and referenced_name != 'DUAL'\n"               //$NON-NLS-1$
           +"UNION\n"                                                                        //$NON-NLS-1$ 
           +"select owner, name, type, referenced_owner, referenced_name, referenced_type\n" //$NON-NLS-1$
           +"  from index_dependencies\n"                                                    //$NON-NLS-1$
           +" where (referenced_owner,referenced_name,referenced_type) in (%s)\n"            //$NON-NLS-1$
           +"UNION\n"                                                                        //$NON-NLS-1$
           +"select owner, name, type, referenced_owner, referenced_name, referenced_type\n" //$NON-NLS-1$
           +"  from all_dependencies\n"                                                      //$NON-NLS-1$
           +" where (owner,name,type) in (%s)\n"                                             //$NON-NLS-1$
           +"   and referenced_owner != 'SYS' and referenced_name != 'DUAL'\n"               //$NON-NLS-1$
           +"UNION\n"                                                                        //$NON-NLS-1$ 
           +"select owner, name, type, referenced_owner, referenced_name, referenced_type\n" //$NON-NLS-1$
           +"  from all_dependencies\n"                                                      //$NON-NLS-1$
           +" where (referenced_owner,referenced_name,referenced_type) in (%s)\n"            //$NON-NLS-1$
           +"\n" //$NON-NLS-1$
           ;
    private static final String OWNER = "OWNER"; //$NON-NLS-1$
    private static final String NAME = "NAME";   //$NON-NLS-1$
    private static final String TYPE = "TYPE";   //$NON-NLS-1$
    private static final String REFERENCED_OWNER = "REFERENCED_OWNER"; //$NON-NLS-1$
    private static final String REFERENCED_NAME = "REFERENCED_NAME";   //$NON-NLS-1$
    private static final String REFERENCED_TYPE = "REFERENCED_TYPE";   //$NON-NLS-1$
    
    private Context context;
    private Collection<Node> selectedNodes = new ArrayList<>();
    private Map<String,Node> nodeMap = new HashMap<>();
    private Map<String,Edge> edgeMap = new HashMap<>();
    private String criteria;
    
    /**
     * @param context the context from SQL developer
     */
    public DependencyExampleModel(Context currentContext) {
        // IMPORTANT! Snapshot content as it is transient.
        // Context.equals compares content so can be used to detect changes 
        // where if we kept the original reference, its contents would update
        // with every UI selection change. (Views check every 250ms. That's
        // how property inspectors, structure displays, etc. stay in sync.)
        /*
         * Well, how about that. True, in general for how the FCP works.
         * However SQLDeveloper is using a ViewerNode wrapper that stays 
         * constant within type on the navigator. this means selecting e.g.,
         * a TABLE, then another won't cause the context to fail equals.
         * See checkSelectionsChanged for how we get around that.  
         */
        context = new Context(currentContext); 
    }

    public Context getContext() {
        return context;
    }
    
    /**
     * @return boolean indicating if the model has data
     */
    public boolean isLoaded() {
        return !nodeMap.isEmpty();
    }

    /**
     * Load the dependency model
     */
    public void load() {
         criteria = generateSelectionCriteria(context, true);
         String query = String.format(DEPENDENCY_QUERY4, criteria, criteria, criteria, criteria);
         Connection conn = new DBObject(context.getNode()).getConnection();
         if (LockManager.lock(conn)) {
             try {
                 DBUtil dbUtil = DBUtil.getInstance(conn);
                 ResultSet rs = dbUtil.executeQuery(query, /*no binds*/(List<?>)null);
                 Throwable t = dbUtil.getLastException();
                 if (t != null) {
                     throw t;
                 }
                 while (rs.next()) {
                     Node from = findOrCreateNode(rs.getString(OWNER), rs.getString(NAME), rs.getString(TYPE));
                     Node to = findOrCreateNode(rs.getString(REFERENCED_OWNER), rs.getString(REFERENCED_NAME), rs.getString(REFERENCED_TYPE));
                     findOrCreateEdge(from, to);
                 }
             } catch (Throwable t) {
                 String msg = "Unable to load model for ("+criteria+')';  // TODO NLS!
                 Logger.severe(getClass(), msg, t);
                 selectedNodes.add(findOrCreateNode("","",msg));
             } finally {
                 LockManager.unlock(conn);
             }
         }
    }
    
    public Collection<Node> getNodeList() {
        return nodeMap.values();
    }
    
    public Collection<Edge> getEdgeList() {
        return edgeMap.values();
    }
    
    public Collection<Node> getSelectedNodes() {
        return selectedNodes;
    }
    
    /**
     * @return a string of the format (owner,name,type)[,(owner,name,type)]... 
     *         containing each selected object
     */
    @SuppressWarnings("rawtypes")
    private String generateSelectionCriteria(Context context, boolean updateSelectedNodes) {
        Element[] selection = context.getSelection();
        if (0 == selection.length && context.getNode() != null) {
            selection = new Element[] {context.getNode()};
        }
        StringBuilder builder = new StringBuilder();
        boolean first = true;
        for (Element element : selection) {
            if (element instanceof ViewerNode) {
                // For the object viewer framework, the node will be wrapped
                // (called due to DependencyExampleGraphViewer.xml entry,
                // not via DependencyExampleController)
                element = ((ViewerNode)element).getDBObject().getNode();
            }
            if (element instanceof DBObjectTypeNode) {
                DBObjectTypeNode node = (DBObjectTypeNode)element;
                if (!first) {
                    builder.append(',');
                }
                first = false;
                builder.append("('").append(node.getSchemaName()) //$NON-NLS-1$
                .append("','").append(node.getShortLabel())       //$NON-NLS-1$
                .append("','").append(node.getObjectType())       //$NON-NLS-1$
                .append("')");                                    //$NON-NLS-1$
                if (updateSelectedNodes) {
                    selectedNodes.add(findOrCreateNode(node.getSchemaName(),node.getShortLabel(),node.getObjectType()));
                }
            }
            // just ignore anything else
        }
        return builder.toString();
    }

    private Node findOrCreateNode(String owner, String name, String type) {
        Node node = nodeMap.get(Node.getKey(owner, name, type));
        if (null == node) {
            node = new Node(owner, name, type);
            nodeMap.put(node.getKey(), node);
        }
        return node;
    }
    
    private Edge findOrCreateEdge(Node from, Node to) {
        Edge edge = edgeMap.get(Edge.getKey(from, to));
        if (null == edge) {
            edge = new Edge(from, to);
            edgeMap.put(edge.getKey(), edge);
        }
        return edge;
    }
    
    public static class Node {
        public String owner;
        public String name;
        public String type;
        public Node(String anOwner, String aName, String aType) {
            owner = anOwner;
            name = aName;
            type = aType;
        }
        public static String getKey(String owner, String name, String type) {
            // Note alternate ordering is to make drill link composition easier
            return owner+":"+type+":"+name;
        }
        public String getKey() {
            return getKey(owner, name, type);
        }
        @Override
        public String toString() {
            return getKey();
        }
    }
    
    public static class Edge {
        public Node from;
        public Node to;
        public Edge(Node fromNode, Node toNode) {
            from = fromNode;
            to = toNode;
        }
        public static String getKey(Node from, Node to) {
            return from.getKey()+"->"+to.getKey();
        }
        public String getKey() {
            return Edge.getKey(from, to);
        }
        @Override
        public String toString() {
            return getKey();
        }
    }

    /**
     * @param key string of the form OWNER:TYPE:NAME for an object
     */
    public void performDrill(String key) {
        Logger.info(getClass(), "*****Drill>>>>>"+key); 
        String linkText = key + ":oracle.dbtools.raptor.controls.grid.DefaultDrillLink"; //$NON-NLS-1$
        final String[] tokens = linkText.split(":");
        IDrillLink link = DrillLinkRegistry.getInstance().getDrillLink(tokens, getConnectionName());
        if (link != null) {
            link.performDrill();
        }
        Logger.info(getClass(), "*****Drill<<<<<"+key); 
    }

    private String connectionName;
    /**
     * @return
     */
    private String getConnectionName() {
        if (null == connectionName) {
            connectionName = new DBObject(context.getNode()).getConnectionName();
        }
        return connectionName;
    }

    /**
     * @param context
     * @return true if the selections in the context are different than the 
     *         ones in this model
     */
    public boolean checkSelectionsChanged(Context context) {
        String contextSelectionCriteria = generateSelectionCriteria(context, false);
        return !contextSelectionCriteria.equals(criteria);
    }

}
