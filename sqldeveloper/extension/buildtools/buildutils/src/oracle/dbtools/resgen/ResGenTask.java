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

package oracle.dbtools.resgen;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Writer;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.FileSet;
import org.apache.tools.ant.types.resources.FileResource;

/**
 * Ant {@link Task} for generating our Resource wrapper classes. The wrapper classes provide a convenient
 * API for accessing the resource strings while allowing us to keep the actual resources as .properties files
 * @author John McGinnis
 */
public class ResGenTask extends Task {
    private File m_inputList;
    private File m_srcRoot;
    private File m_outputRoot;
    private List<FileResource> m_rtsFiles = new ArrayList<FileResource>();
    
    private String m_template;

    /**
     * @param fName filename to open
     */
    public void setInputFile(final String fName) {
        File root = getProject().getBaseDir();
        m_inputList = new File(root, fName);
    }

    /**
     * @param root directory
     */
    public void setSourceRoot(final String root) {
        File base = getProject().getBaseDir();
        m_srcRoot = new File(base, root);
    }

    /**
     * Set the output root directory
     * @param root directory
     */
    public void setOutputRoot(String root) {
        File rootFile = new File(root);
        if ( rootFile.isAbsolute() ) {
            m_outputRoot = rootFile;
        } else {
            File base = getProject().getBaseDir();
            m_outputRoot = new File(base, root);
        }
    }
    
    @SuppressWarnings("rawtypes")
    public void addConfiguredFileset(FileSet fs) {
        for ( Iterator iter = fs.iterator(); iter.hasNext(); ) {
            Object o = iter.next();
            if ( o instanceof FileResource ) {
                FileResource fr = ( FileResource ) o;
                m_rtsFiles.add(fr);
            }
        }
    }

    @Override
    public void execute() {
        if (m_inputList == null) {
            if ( m_rtsFiles.size() == 0 ) {
                throw new BuildException("No file list specified");
            }
        }
        if (m_srcRoot == null) {
            throw new BuildException("No source root specified");
        }
        if (m_outputRoot == null) {
            throw new BuildException("No output root specified");
        }

        // First, process the explicitly listed files
        List<FileResource> files = getResourceFiles();
        if (files.size() == 0) {
            log("Skipping generating files for " + m_srcRoot);
        }
        
        processFileset(files);
        
        // Now process the files we got from searching the path
        processFileset(m_rtsFiles);
    }

    /**
     * Process a list of files
     * @param files
     */
    void processFileset(List<FileResource> files) {
        for ( FileResource file : files ) {
            String path = file.getName();
            
            int idx = path.lastIndexOf('.');
            path = idx > 0 ? path.substring(0, idx) : path;
            
            String pkg;
            String cls;
            
            idx = path.lastIndexOf(File.separatorChar);
            if ( idx > 0 ) {
                pkg = path.substring(0, idx).replace(File.separatorChar, '.');
                cls = path.substring(idx + 1);
            } else {
                pkg = "";
                cls = path;
            }
            
            File outFile = new File(m_outputRoot, path + ".java");
            processFile(file.getFile(), outFile, pkg, cls);
        }
    }

    /**
     * Process a resources file
     * @param propFile
     * @param outFile
     * @param pkg
     * @param cls
     */
    void processFile(File propFile, File outFile, String pkg, String cls) {
        final String template = getTemplate();
        
        if (  outFile.exists() && outFile.lastModified() > propFile.lastModified() ){
            log("Skipping properties file " + propFile);
        } else {
            log("Processing properties file " + propFile);

            Properties props = new Properties();
            InputStream is = null;
            try {
                is = new FileInputStream(propFile);
                props.load(is);
            } catch (IOException e) {
                log("Error processing " + propFile + ": " + e.getLocalizedMessage());
                return;
            } finally {
                if (is != null) try {
                    is.close();
                } catch (Exception ex) {
                }
            }
   
            
            if (props.size() > 0) {
                // Build up our list of property keys
                StringBuilder propDecls = new StringBuilder();
                for (Object key: props.keySet()) {
                    propDecls.append(MessageFormat.format("    public static final String {0} = \"{1}\"; //$NON-NLS-1$\n", key.toString().replace('.', '_'), key));
                }
                String outText = MessageFormat.format(template, pkg, cls, propDecls);

                // Create the output Dir
                File outDir = outFile.getParentFile();
                if (!outDir.exists()) {
                    if (!outDir.mkdirs()) {
                        log("Could not create directory path " + outDir);
                        return;
                    }
                }
                // Generate our Java class
                Writer out = null;
                try {
                    out = new FileWriter(outFile);
                    out.write(outText);
                } catch (IOException e) {
                    log("Error writing file " + outFile + ": " + e.getLocalizedMessage());
                } finally {
                    if (out != null) try {
                        out.close();
                    } catch (Exception e) {
                    }
                }
            }
        }
    }

    private List<FileResource> getResourceFiles() {
        List<FileResource> files = new ArrayList<FileResource>();
        if (m_inputList.exists()) {
        	BufferedReader r = null;
            try {
                r = new BufferedReader(new FileReader(m_inputList));
                String line;
                while ((line = r.readLine()) != null) {
                    line = line.trim();
                    if (line.length() > 0) {
                        String path = line.replace('.', File.separatorChar);
                        String fName = path + ".properties";
                        files.add(new FileResource(m_srcRoot, fName));
                    }
                }
            } catch (IOException e) {
                log("Cannot open file " + m_inputList);
            } finally {
            	if (r != null) {
            		try {
						r.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
            	}
            }
        }
        return files;

    }
    
    /**
     * Load up our template file.
     * @return
     */
    private String getTemplate() {
        if ( m_template == null ) {
            // Load the template file
            StringBuilder bldr = new StringBuilder();
            BufferedReader rdr = null;
            try {
                rdr = new BufferedReader(new InputStreamReader(getClass().getResourceAsStream("Resources.template")));
                String s;
                while ((s = rdr.readLine()) != null) {
                    bldr.append(s).append('\n');
                }
            } catch (Exception ex) {
                throw new BuildException("Could not load template " + ex.getLocalizedMessage(), ex);
            } finally {
                if (rdr != null) try {
                    rdr.close();
                } catch (Exception ex) {
                }
            }
            m_template = bldr.toString();
        }
        return m_template;
    }
}
