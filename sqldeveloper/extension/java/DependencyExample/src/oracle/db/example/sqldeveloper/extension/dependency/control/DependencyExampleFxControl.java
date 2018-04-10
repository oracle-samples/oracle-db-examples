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

import javax.imageio.ImageIO;
import javax.swing.SwingUtilities;

import javafx.application.Platform;
import javafx.embed.swing.SwingFXUtils;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.geometry.Bounds;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.SnapshotParameters;
import javafx.scene.control.ContextMenu;
import javafx.scene.control.MenuItem;
import javafx.scene.image.WritableImage;
import javafx.scene.input.ContextMenuEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.Pane;
import javafx.scene.layout.StackPane;
import javafx.scene.transform.Transform;
import oracle.db.example.sqldeveloper.extension.dependency.DependencyExampleResources;
import oracle.db.example.sqldeveloper.extension.dependency.DependencyExampleUtils;
import oracle.db.example.sqldeveloper.extension.dependency.model.DependencyExampleModel;
import oracle.dbtools.javafx.scene.CustomControl;
import oracle.dbtools.raptor.ui.URLFileChooser;
import oracle.dbtools.util.Logger;
import oracle.ide.Ide;
import oracle.ide.controls.WaitCursor;

/**
 * DependencyExampleFxControl an javaFX custom control to contain the vworkflow UI
 *
 * @author <a href="mailto:brian.jeffries@oracle.com?subject=oracle.dbtools.raptor.dependency.control.DependencyExampleFxControl">Brian Jeffries</a>
 * @since SQL Developer 4.2
 */

public class DependencyExampleFxControl extends CustomControl {
    
    public DependencyExampleFxControl() {
        super(); // just for debug break
    }
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
        
            MenuItem item = new MenuItem(DependencyExampleResources.get(DependencyExampleResources.DependencyExampleFxControl_saveSnapshot));
            item.addEventHandler(ActionEvent.ACTION, (e) -> {
                saveSnapshot();
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
     * Save image of diagram to png file - note this is the entire diagram, not just the viewport view 
     * (which we could do as an additional option?)
     */
    private void saveSnapshot() {
        String operation = DependencyExampleResources.get(DependencyExampleResources.DependencyExampleFxControl_saveSnapshot);
        SwingUtilities.invokeLater(() -> {
            try {
                URLFileChooser chooser = DependencyExampleUtils.getURLFileChooser("oracle.dbtools.raptor.dependency-image", DependencyExampleUtils.PNGFILE_FILE); //$NON-NLS-1$
                if (URLFileChooser.APPROVE_OPTION == chooser.showSaveDialog(Ide.getMainWindow(), operation)) {
                    Platform.runLater(() -> {
                        try {
                            // TODO background process? pretty sure it needs the fx platform
// This way would be "what you see [in the viewport] is what you get"
//                            WritableImage wim = new WritableImage((int) Math.round(diagram.getWidth()), (int) Math.round(diagram.getHeight()));
                            Bounds bounds = diagram.boundsInParentProperty().get();
                            WritableImage wim = new WritableImage((int) Math.round(bounds.getWidth())+10, (int) Math.round(bounds.getHeight())+10);
                            SnapshotParameters params = new SnapshotParameters();
                            params.setTransform(Transform.translate(5, 5)); // added 10px to width & height so move origin to 5,5 to give 5px border
                            diagram.snapshot(params, wim);
                            ImageIO.write(SwingFXUtils.fromFXImage(wim, null), "png", chooser.getSelectedFile());
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

    /**
     * 
     */
    private void someOtherAction() {
        // TODO Auto-generated method stub
        
    }

    public Pane getContentPane() {
        return contentPane;
    }
    
    public Parent getRoot() {
// TESTING - Is nesting XRoot not directly on Scene causing UI issues? YES - 
//           looks like XRoot.headsUpDisplay is using scene info, not Parent
//           Hmm create scenegraph as XRoot [ diagram= XDiagram [child = dependencyExampleFxControl [contentPane = FxDiagram]]]??
// FxDiagram has internal assumptions it is the root node of a scene so bypass "this" control completely
// and the diagram root. The normal way would be to add your content in createUI and 
// return (Parent) dependencyExampleFxControl; here        
        createUI();
        Parent p = (Parent) diagram.getRootNode();
        diagram.setUpExportPngAction(DependencyExampleResources.get(DependencyExampleResources.DependencyExampleFxControl_saveSnapshot), 
                                     () -> {
                                         saveSnapshot();
                                     });
        diagram.getStyleClass().add("DependencyExampleFxControl"); // for CSS styling
        // CSS is messed up TODO Run with ScenicView someday & find out how the scene graph is being composed
        // See similar notes in FxDiagram.java
        URL stylesheet = this.getClass().getResource("DependencyExampleFxControl.css");
        String stylesheetX = stylesheet.toExternalForm();
        diagram.getStylesheets().add(stylesheetX);
        return p;
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
     * @param waitCursor 
     */
    public void setViewModel(DependencyExampleModel aViewModel, final WaitCursor waitCursor) {
        viewModel = aViewModel;
        Platform.runLater(() -> {
            getViewModel().load();
            updateUI();
            diagram.applyCss();
            diagram.layout();
            SwingUtilities.invokeLater(() -> {
            	waitCursor.hide();
            });
        });
    }

    private void createUI() {
        if (null == diagram) {
            Logger.info(getClass(), "*****createUI*****"); //$NON-NLS-1$
            diagram = new FxDiagram();
// TESTING            
//            contentPane.getChildren().add(diagram.getRootNode());
        }
    }
    
    private void updateUI() {
        createUI();
        Logger.info(getClass(), "*****updateUI*****"); //$NON-NLS-1$
        diagram.setModel(getViewModel());
    }
    
}
