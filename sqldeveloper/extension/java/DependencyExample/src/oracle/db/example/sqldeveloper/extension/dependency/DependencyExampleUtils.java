package oracle.db.example.sqldeveloper.extension.dependency;

import oracle.dbtools.raptor.ui.URLFileChooser;
import oracle.ide.net.URLFileSystem;
import oracle.ide.net.URLFilter;
import oracle.ide.net.WildcardURLFilter;

/**
 * Container for static utility methods
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.db.example.sqldeveloper.extension.dependency.DependencyExampleUtils">Brian Jeffries</a>
 * @since SQL Developer 4.2
 */
public class DependencyExampleUtils {

    public static final URLFilter PNGFILE_FILE = 
            new WildcardURLFilter("*.png", URLFileSystem.isLocalFileSystemCaseSensitive(), DependencyExampleResources.getString(DependencyExampleResources.LABEL_PNG_FILES)); //$NON-NLS-1$
    public static final URLFilter XMLFILE_FILE = 
            new WildcardURLFilter("*.xml", URLFileSystem.isLocalFileSystemCaseSensitive(), DependencyExampleResources.getString(DependencyExampleResources.LABEL_XML_FILES)); //$NON-NLS-1$

    /**
     * Utility method to get a file chooser initialized for the specified context
     *   and url filter.<p/>
     * 
     * NOTE: The chooser also has various
     * <code>URLFileChooserPanel URLFileChooser.createURLFileChooserPanel(...)</code>
     * to get a panel with context based MRU drop down, type ahead and button for 
     * chooser dialog that can be placed in your UI. The panel can be treated as a 
     * chooser for most circumstances. (It mirrors the chooser API.)
     * 
     * @param pathContext A string representing the 'context' for this chooser use.
     *                    It is the key to the list of recent paths for creating
     *                    the icon bar. This will also include entries from the global
     *                    (no context) list.
     * @param urlFilter A URL Filter for what file types are accepted 
     * @return the initialized chooser.
     */
    public static URLFileChooser getURLFileChooser(String pathContext, URLFilter urlFilter) {
        URLFileChooser chooser = new URLFileChooser();
        chooser.setPathContext(pathContext);
        chooser.clearChooseableURLFilters();
        chooser.addChooseableURLFilter(urlFilter);
        chooser.setSelectionScope(URLFileChooser.FILES_ONLY);
        chooser.setSelectionMode(URLFileChooser.SINGLE_SELECTION);
        chooser.setShowJarsAsDirs(false);
        return chooser;
    }
    
    
}
