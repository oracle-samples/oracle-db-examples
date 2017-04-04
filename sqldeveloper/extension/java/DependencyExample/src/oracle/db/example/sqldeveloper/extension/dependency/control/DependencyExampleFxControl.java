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

package oracle.db.example.sqldeveloper.extension.dependency.control;

import java.net.URL;
import java.util.ResourceBundle;

import javax.swing.SwingUtilities;

import javafx.application.Platform;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.Parent;
import javafx.scene.control.ContextMenu;
import javafx.scene.control.MenuItem;
import javafx.scene.input.ContextMenuEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.Pane;
import javafx.scene.layout.StackPane;

import oracle.db.example.sqldeveloper.extension.dependency.DependencyExampleResources;
import oracle.db.example.sqldeveloper.extension.dependency.model.DependencyExampleModel;
import oracle.dbtools.javafx.scene.CustomControl;
import oracle.dbtools.raptor.ui.URLFileChooser;
import oracle.dbtools.util.Logger;
import oracle.ide.Ide;
import oracle.ide.net.URLFileSystem;
import oracle.ide.net.URLFilter;
import oracle.ide.net.WildcardURLFilter;

/**
 * DependencyExampleFxControl an javaFX custom control to contain the vworkflow UI
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.dbtools.raptor.dependency.control.DependencyExampleFxControl">Brian Jeffries</a>
 * @since SQL Developer 4.2
 */

public class DependencyExampleFxControl extends CustomControl {
    /*
     * N.B. Because of the way FXMLLoader determines the caller and then the
     *      class loader for reflection, either we have to be calling FXMLLoader
     *      from this (osgi) module, or the @FXML injected things must be public.
     *      So much for CustomControl ...
     */

    @FXML // ResourceBundle that was given to the FXMLLoader
    public ResourceBundle resources;

    @FXML // URL location of the FXML file that was given to the FXMLLoader
    public URL location;

    @FXML // fx:id="dependencyExampleFxControl"
    public BorderPane dependencyExampleFxControl; // Value injected by FXMLLoader

    @FXML // fx:id="contentPane"
    public StackPane contentPane; // Value injected by FXMLLoader

    @FXML // This method is called by the FXMLLoader when initialization is complete
    public void initialize() {
        assert dependencyExampleFxControl != null : "fx:id=\"dependencyExampleFxControl\" was not injected: check your FXML file 'DependencyExampleFxControl.fxml'.";
        assert contentPane != null : "fx:id=\"contentPane\" was not injected: check your FXML file 'DependencyExampleFxControl.fxml'.";
    }
    
    private ContextMenu contextMenu;
    @FXML
    public void onContextMenuRequested(ContextMenuEvent event) {
        if (null == contextMenu) {
            contextMenu = new ContextMenu();
        
            MenuItem item = new MenuItem(DependencyExampleResources.get(DependencyExampleResources.DependencyExampleFxControl_SomeAction));
            item.addEventHandler(ActionEvent.ACTION, (e) -> {
                someAction();
            });
            contextMenu.getItems().add(item);
            item = new MenuItem(DependencyExampleResources.get(DependencyExampleResources.DependencyExampleFxControl_SomeOtherAction));
            item.addEventHandler(ActionEvent.ACTION, (e) -> {
                someOtherAction();
            });
            contextMenu.getItems().add(item);
        }
        //FxDiagram has it's own menu. See FxDiagram.getRootNode
        //contextMenu.show(contentPane, event.getScreenX(), event.getScreenY());
    }
    
    /**
     * 
     */
    private void someAction() {
        // TODO Auto-generated method stub
        
    }

    /**
     * 
     */
    private void someOtherAction() {
        // TODO Auto-generated method stub
        
    }

    static final URLFilter PNGFILE_FILE = 
            new WildcardURLFilter("*.png", URLFileSystem.isLocalFileSystemCaseSensitive(), DependencyExampleResources.getString(DependencyExampleResources.LABEL_PNG_FILES)); //$NON-NLS-1$
    static final URLFilter XMLFILE_FILE = 
            new WildcardURLFilter("*.xml", URLFileSystem.isLocalFileSystemCaseSensitive(), DependencyExampleResources.getString(DependencyExampleResources.LABEL_XML_FILES)); //$NON-NLS-1$

    private URLFileChooser getURLFileChooser(String pathContext, URLFilter urlFilter) {
        URLFileChooser chooser = new URLFileChooser();
        chooser.setPathContext(pathContext);
        chooser.clearChooseableURLFilters();
        chooser.addChooseableURLFilter(urlFilter);
        chooser.setSelectionScope(URLFileChooser.FILES_ONLY);
        chooser.setSelectionMode(URLFileChooser.SINGLE_SELECTION);
        chooser.setShowJarsAsDirs(false);
        return chooser;
    }
    
    /**
     * Save image of vFlow to png file - note this is the entire flow, not just the viewport view 
     * (which we could do as an additional option?)
     */
    private void saveSnapshot() {
        String operation = "save Snapshot(png)"; //DependencyExampleResources.get(DependencyExampleResources.DependencyExampleFxControl_saveSnapshot);
        SwingUtilities.invokeLater(() -> {
            try {
                URLFileChooser chooser = getURLFileChooser("oracle.dbtools.raptor.dependency-image", PNGFILE_FILE); //$NON-NLS-1$
                if (URLFileChooser.APPROVE_OPTION == chooser.showSaveDialog(Ide.getMainWindow(), operation)) {
                    Platform.runLater(() -> {
                        try {
                            // TODO background process? pretty sure it needs the fx platform
//                            WritableImage wim = new WritableImage((int) Math.round(vFlowPane.getWidth()), (int) Math.round(vFlowPane.getHeight()));
//                            SnapshotParameters params = new SnapshotParameters();
//// TODO                            vFlowPane.snapshot(params, wim);
//                            ImageIO.write(SwingFXUtils.fromFXImage(wim, null), "png", chooser.getSelectedFile());
                        } catch (Exception e) {
                            Logger.severe(getClass(), operation, e);
                        }
                    });
                }
            } catch (Exception e) {
                Logger.warn(getClass(), operation, e);
            }
        });
    }

    public Pane getContentPane() {
        return contentPane;
    }
    
    public Parent getRoot() {
        return (Parent) dependencyExampleFxControl;
    }
    
    
    private DependencyExampleModel viewModel;
    private FxDiagram diagram;
    
    /**
     * @return the DependencyExampleModel
     */
    public DependencyExampleModel getViewModel() {
        return viewModel;
    }

    /**
     * @param aViewModel the viewModel to set
     */
    public void setViewModel(DependencyExampleModel aViewModel) {
        viewModel = aViewModel;
        Platform.runLater(() -> {
            getViewModel().load();
            updateUI();
            //contentPane.applyCss();
            //contentPane.layout();
        });
    }

    private void createUI() {
        if (null == diagram) {
            Logger.info(getClass(), "*****createUI*****"); //$NON-NLS-1$
            diagram = new FxDiagram();
            contentPane.getChildren().add(diagram.getRootNode());
        }
    }
    
    private void updateUI() {
        createUI();
        Logger.info(getClass(), "*****updateUI*****"); //$NON-NLS-1$
        diagram.setModel(getViewModel());
    }
    
}
