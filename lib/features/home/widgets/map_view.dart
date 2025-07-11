import 'package:arcgis_app_demo/core/providers/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum ToolMenus { Reticle_Vertex_Tool, Vertex_Tool }

// Helper extension để capitalize string
extension StringCapitalization on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// Bottom sheet widget cho snap settings
class BottomSheetSettings extends StatelessWidget {
  final VoidCallback onCloseIconPressed;
  final List<Widget> Function(BuildContext) settingsWidgets;

  const BottomSheetSettings({
    Key? key,
    required this.onCloseIconPressed,
    required this.settingsWidgets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: onCloseIconPressed,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: settingsWidgets(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class MapViewWidget extends StatefulWidget {
  final ArcGISMapViewController controller;
  final void Function()? onMapViewReady;
  final void Function(Offset)? onTap;
  final bool overlayLoading;

  const MapViewWidget({
    Key? key,
    required this.controller,
    this.onMapViewReady,
    this.onTap,
    this.overlayLoading = false,
  }) : super(key: key);

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  // Geometry Editor và các tools
  late GeometryEditor _geometryEditor;
  final _vertexTool = VertexTool();
  final _reticleVertexTool = ReticleVertexTool();  
  final _graphicsOverlay = GraphicsOverlay();

  // UI state variables
  bool _snapSettingsVisible = false;

  // Geometry Editor state variables
  bool _geometryEditorCanUndo = false;
  bool _geometryEditorIsStarted = false;
  bool _geometryEditorHasSelectedElement = false;
  bool _snappingEnabled = false;
  bool _geometryGuidesEnabled = false;
  bool _featureSnappingEnabled = true;
  bool _showEditToolbar = true;

  // Selected geometry type và tool
  Graphic? _selectedGraphic;
  // Custom symbols
  late SimpleMarkerSymbol _flagSymbol;
  late SimpleMarkerSymbol _warningSymbol;

  // Snap source lists
  final List<SnapSourceSettings> _pointLayerSnapSources = [];
  final List<SnapSourceSettings> _polylineLayerSnapSources = [];
  final List<SnapSourceSettings> _graphicsOverlaySnapSources = [];

  // Menu items
  // late List<DropdownMenuItem<GeometryType>> _geometryTypeMenuItems;
  // late List<DropdownMenuItem<GeometryEditorTool>> _toolMenuItems;

  ToolMenus toolMenusView = ToolMenus.Reticle_Vertex_Tool;

  @override
  void initState() {
    super.initState();

    _initializeCustomSymbols();

    // Khởi tạo GeometryEditor
    _geometryEditor = GeometryEditor();
    _geometryEditor.tool = _reticleVertexTool;

    // Set up listeners
    _setupGeometryEditorListeners();

    // Cấu hình menu items
    // _geometryTypeMenuItems = configureGeometryTypeMenuItems();
    // _toolMenuItems = configureToolMenuItems();

    // Set geometry editor to controller
    widget.controller.geometryEditor = _geometryEditor;

    // Add graphics overlay to controller
    widget.controller.graphicsOverlays.add(_graphicsOverlay);
  }
  void _initializeCustomSymbols() {
    // Flag symbol - màu đỏ với icon flag (tăng size để dễ thấy)
    _flagSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.circle,
      color: const Color.fromARGB(255, 255, 0, 0), // Màu đỏ
      size: 20, // Tăng size từ 16 lên 20
    );    // Warning symbol - màu cam với icon warning
    _warningSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.triangle,
      color: const Color.fromARGB(255, 255, 165, 0), // Màu cam
      size: 20,
    );
  }

  void _setupGeometryEditorListeners() {
    _geometryEditor.onCanUndoChanged.listen((canUndo) {
      setState(() => _geometryEditorCanUndo = canUndo);
    });

    _geometryEditor.onIsStartedChanged.listen((isStarted) {
      setState(() => _geometryEditorIsStarted = isStarted);
    });

    _geometryEditor.onSelectedElementChanged.listen((selectedElement) {
      setState(
        () => _geometryEditorHasSelectedElement = selectedElement != null,
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isActive = ref.watch(activeToolProvider);
        final isActiveButtonTool = ref.watch(activeToolButtonProvider);
        final isActiveTSAH = ref.watch(traceDataProvider) ?? ref.watch(traceHistoryDataProvider);
        // Listen to tool changes without triggering rebuilds
        ref.listen<ToolType?>(activeToolButtonProvider, (previous, next) {
          if (next != null) {
            // Tool được chọn - bắt đầu editing
            if (!_geometryEditorIsStarted) {
              startEditingWithGeometryType(GeometryType.point);
            }
          } else {
            // Không có tool nào được chọn - stop editing
            if (_geometryEditorIsStarted) {
              _geometryEditor.stop();
              setState(() {
                _geometryEditorIsStarted = false;
                _selectedGraphic = null;
              });
            }
          }
        });

        return Stack(
          children: [
            ArcGISMapView(
              controllerProvider: () => widget.controller,
              onMapViewReady: widget.onMapViewReady,
              onTap: (screenPoint) async {
                // Đầu tiên check xem có tap vào graphic để edit không
                await handleGraphicTap(screenPoint);

                // Sau đó gọi callback onTap ban đầu nếu có
                if (widget.onTap != null) {
                  widget.onTap!(screenPoint);
                }
              },
            ),
            Visibility(
              visible: isActive == true && isActiveButtonTool != null,
              child: buildBottomMenu(context),
            ),
            Visibility(
              visible: _showEditToolbar && isActive == true && isActiveButtonTool != null,
              child: buildEditingToolbar(ref),
            ),
            Visibility(
              visible: _snapSettingsVisible && isActive == true && isActiveButtonTool != null,
              child: buildSnapSettings(context),
            ),
            Visibility(
              visible: isActiveTSAH != null && isActive == false,
              child: buildTSAH(context,ref)
            ),
            if (widget.overlayLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  // Method để start editing với geometry type
  void startEditingWithGeometryType(GeometryType geometryType) {
    if (!_geometryEditorIsStarted) {
      _geometryEditor.startWithGeometryType(geometryType);

      // Sync snap settings khi bắt đầu editing
      synchronizeSnapSettings();
    }
  }

  // Method để sync snap settings
  void synchronizeSnapSettings() {
    _geometryEditor.snapSettings.syncSourceSettings();

    setState(() {
      _snappingEnabled = true;
      _geometryGuidesEnabled = true;
      _featureSnappingEnabled = true;
    });

    _geometryEditor.snapSettings.isEnabled = true;
    _geometryEditor.snapSettings.isGeometryGuidesEnabled = true;
    _geometryEditor.snapSettings.isFeatureSnappingEnabled = true;

    // Clear previous snap sources
    _pointLayerSnapSources.clear();
    _polylineLayerSnapSources.clear();
    _graphicsOverlaySnapSources.clear();

    // Create snap source settings for each geometry type
    for (final sourceSettings in _geometryEditor.snapSettings.sourceSettings) {
      sourceSettings.isEnabled = true;

      if (sourceSettings.source is FeatureLayer) {
        final featureLayer = sourceSettings.source as FeatureLayer;
        if (featureLayer.featureTable != null) {
          final geometryType = featureLayer.featureTable!.geometryType;
          if (geometryType == GeometryType.point) {
            _pointLayerSnapSources.add(sourceSettings);
          } else if (geometryType == GeometryType.polyline) {
            _polylineLayerSnapSources.add(sourceSettings);
          }
        }
      } else if (sourceSettings.source is GraphicsOverlay) {
        _graphicsOverlaySnapSources.add(sourceSettings);
      }
    }
  }  // Method để stop và save
  void stopAndSave(ref) async {
    if (!_geometryEditorIsStarted) return;

    final geometry = _geometryEditor.stop();
    if (geometry != null && geometry is ArcGISPoint) {
      if (_selectedGraphic != null) {
        // If there was a selected graphic being edited, update it.
        _selectedGraphic!.geometry = geometry;
        _selectedGraphic!.isVisible = true;
        // Reset the selected graphic to null.
        _selectedGraphic = null;
      } else {
        // If there was no existing graphic, create a new one and add to the graphics overlay.
        final graphic = Graphic(geometry: geometry);
        
        // Apply symbol based on active tool type
        final activeTool = ref.read(activeToolButtonProvider);
        
        switch (activeTool) {
          case ToolType.flag:
            graphic.symbol = _flagSymbol;
            break;
          case ToolType.barrier:
            graphic.symbol = _warningSymbol;
            break;
          default:
            // Fallback symbol nếu không có tool nào được chọn
            graphic.symbol = _flagSymbol;
            break;
        }

        // Try to identify feature at clicked location (similar to ReactJS hitTest)
        String layerInfo = "Unknown";
        String loaiOng = "OngPhanPhoi"; // Default value like ReactJS
        int? objectId;
        double finalX = geometry.x; // Default to clicked coordinates
        double finalY = geometry.y; // Default to clicked coordinates
        try {
          final map = widget.controller.arcGISMap;
          if (map != null && map.operationalLayers.isNotEmpty) {
            final projectionUrl = 'https://gis.phuwaco.com.vn/server/rest/services/Utilities/Geometry/GeometryServer/project';
            final tphcmSpatialReferenceMap =  {
              "wkt": 'PROJCS["TPHCM_VN2000",GEOGCS["GCS_VN_2000",DATUM["D_Vietnam_2000",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",105.75],PARAMETER["Scale_Factor",0.9999],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]',
            };
            final tphcmSpatialReference = SpatialReference.fromJson(tphcmSpatialReferenceMap);
            // Try to find a feature layer at this location (similar to hitTest)
            // final screenPoint = widget.controller.locationToScreen(mapPoint: geometry);
            // final identifyResults = await widget.controller.identifyLayers(
            //   screenPoint: screenPoint,
            //   tolerance: 22,
            // );
            final projectionResult = await projectPointGeometry(
              projectionUrl,
              geometry.spatialReference!,
              tphcmSpatialReference, // Use TPHCM_VN2000 instead of featureLayer.spatialReference
              geometry,
              ref,
            );

            if (projectionResult != null && projectionResult['geometries'] != null) {
              final geometries = projectionResult['geometries'] as List;
              if (geometries.isNotEmpty) {
                final projectedGeometry = geometries[0];
                finalX = projectedGeometry['x']?.toDouble() ?? geometry.x;
                finalY = projectedGeometry['y']?.toDouble() ?? geometry.y;

                objectId = await findObjectIdOngPhanPhoi(
                  x: finalX,
                  y: finalY,
                  inSr: tphcmSpatialReference,
                  outSR: tphcmSpatialReference,
                  ref: ref,
                );
              }
            } else {
              print("Projection failed, using original coordinates");
              finalX = geometry.x;
              finalY = geometry.y;
            }
          }
        } catch (e) {
          print("Error in feature identification: $e");
          // Continue with default values and clicked coordinates
        }
        
        // Store additional information in graphic attributes
        graphic.attributes['toolType'] = activeTool.toString().split('.').last;
        graphic.attributes['layerInfo'] = layerInfo;
        graphic.attributes['loaiOng'] = loaiOng;
        graphic.attributes['objectId'] = objectId;
        graphic.attributes['timestamp'] = DateTime.now().millisecondsSinceEpoch;
        
        final enhancedData = <String, dynamic>{
          'geometry': geometry,
          'toolType': activeTool,
          'layerInfo': layerInfo,
          'objectId': objectId ?? 0, // Use 0 as fallback like ReactJS
          'loaiOng': loaiOng,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'x': finalX, // Use projected coordinates if available
          'y': finalY, // Use projected coordinates if available
          'clickedX': geometry.x, // Keep original clicked coordinates for reference
          'clickedY': geometry.y, // Keep original clicked coordinates for reference
        };
        
        ref.read(enhancedGeometryDataProvider.notifier).update(
          (List<Map<String, dynamic>> state) => [...state, enhancedData],
        );

        print("=== Enhanced Data Summary ===");
        print("Tool Type: $activeTool");
        print("Layer Info: $layerInfo");
        print("Feature ObjectId: $objectId");
        print("LoaiOng: $loaiOng");
        print("Final Coordinates: X=$finalX, Y=$finalY");
        print("Clicked Coordinates: X=${geometry.x}, Y=${geometry.y}");
        print("Enhanced data count: ${ref.read(enhancedGeometryDataProvider).length}");
        print("=============================");
        
        // Add graphic to the graphics overlay
        _graphicsOverlay.graphics.add(graphic);

        // Update geometry provider for backward compatibility
        ref.read(listGeometryProvider.notifier).state = _graphicsOverlay.graphics.map((i) => i.geometry!).toList();

        // Check if quick operation is enabled and this is a flag
        final operationType = ref.read(operationTypeProvider);
        if (operationType == OperationType.quickOperation && activeTool == ToolType.flag) {
          // Auto trigger trace operation for quick mode
          Future.delayed(const Duration(milliseconds: 500), () {
            ref.read(handleTraceTypeProvider.notifier).state = ToolType.flag;
          });
        }
        
        print("Saved geometry with layer info: $layerInfo, LoaiOng: $loaiOng");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu geometry thành công (${_graphicsOverlay.graphics.length} điểm)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Method để stop và discard
  void stopAndDiscardEdits() {
    if (!_geometryEditorIsStarted) return;

    _geometryEditor.stop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã hủy chỉnh sửa')));
  }

  // Method để handle tap vào graphics để edit
  Future<void> handleGraphicTap(Offset screenPoint) async {
    if (_geometryEditorIsStarted) return;

    // Perform an identify operation on the graphics overlay at the tapped location
    final identifyResult = await widget.controller.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: screenPoint,
      tolerance: 12,
    );

    // Get the graphics from the identify result
    final graphics = identifyResult.graphics;
    if (graphics.isNotEmpty) {
      final graphic = graphics.first;
      if (graphic.geometry != null) {
        final geometry = graphic.geometry!;

        // Store reference to the selected graphic
        _selectedGraphic = graphic;

        // Hide the selected graphic so that only the version being edited is visible
        graphic.isVisible = false;

        // Start the geometry editor using the geometry of the graphic
        _geometryEditor.startWithGeometry(geometry);

        print(
          "Started editing existing graphic with geometry type: ${geometry.geometryType}",
        );
        return;
      }
    }
  }
  Widget buildBottomMenu(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            color: Theme.of(context).canvasColor.withOpacity(0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SegmentedButton<ToolMenus>(
                      segments: const <ButtonSegment<ToolMenus>>[
                        ButtonSegment<ToolMenus>(
                          value: ToolMenus.Reticle_Vertex_Tool,
                          label: Text('Reticle'),
                        ),
                        ButtonSegment<ToolMenus>(
                          value: ToolMenus.Vertex_Tool,
                          label: Text('Vertex'),
                        ),
                      ],
                      style: SegmentedButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelSmall,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      selected: <ToolMenus>{toolMenusView},
                      onSelectionChanged: (Set<ToolMenus> newSelection) {
                        setState(() {
                          toolMenusView = newSelection.first;
                          if (toolMenusView == ToolMenus.Reticle_Vertex_Tool) {
                            _geometryEditor.tool = _reticleVertexTool;
                          } else {
                            _geometryEditor.tool = _vertexTool;
                          }
                        });
                      },
                    ),
                    // Button để toggle editing toolbar
                    IconButton(
                      iconSize: 30,
                      onPressed: () =>
                          setState(() => _showEditToolbar = !_showEditToolbar),
                      icon: Icon(
                        _showEditToolbar ? Icons.close : Icons.edit,
                        color: _showEditToolbar
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                      ),
                      tooltip: _showEditToolbar ? 'Ẩn toolbar' : 'Hiện toolbar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget buildEditingToolbar(ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                spacing: 1,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Setings',
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() => _snapSettingsVisible = true),
                      child: const Icon(Icons.settings),
                    ),
                  ),
                  // A button to call undo on the geometry editor, if enabled.
                  Tooltip(
                    message: 'Undo',
                    child: ElevatedButton(
                      onPressed:
                          _geometryEditorIsStarted && _geometryEditorCanUndo
                          ? _geometryEditor.undo
                          : null,
                      child: const Icon(Icons.undo),
                    ),
                  ),
                  // A button to delete the selected element on the geometry editor.
                  Tooltip(
                    message: 'Delete selected element',
                    child: ElevatedButton(
                      onPressed:
                          _geometryEditorIsStarted &&
                              _geometryEditorHasSelectedElement &&
                              _geometryEditor.selectedElement != null &&
                              _geometryEditor.selectedElement!.canDelete
                          ? _geometryEditor.deleteSelectedElement
                          : null,
                      child: const Icon(Icons.clear),
                    ),
                  ),
                  Tooltip(
                    message: 'Stop and save edits',
                    child: ElevatedButton(
                      onPressed: _geometryEditorIsStarted ? () => stopAndSave(ref) : null,
                      child: const Icon(Icons.save),
                    ),
                  ),
                  // A button to stop the geometry editor and discard all edits.
                  Tooltip(
                    message: 'Stop and discard edits',
                    child: ElevatedButton(
                      onPressed: _geometryEditorIsStarted
                          ? stopAndDiscardEdits
                          : null,
                      child: const Icon(Icons.not_interested_sharp),
                    ),
                  ),
                  Tooltip(
                    message: 'Clear all graphics',
                    child: ElevatedButton(
                      onPressed: () => clearAllGraphicsWithRef(ref),
                      child: Text("Clean all", style: TextStyle(color: Colors.red,)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSnapSettings(BuildContext context) {
    return BottomSheetSettings(
      onCloseIconPressed: () => setState(() => _snapSettingsVisible = false),
      settingsWidgets: (context) => [
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            maxWidth: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Snap Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    // Add a checkbox to toggle all snapping options.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enable all'),
                        Checkbox(
                          value:
                              _snappingEnabled &&
                              _geometryGuidesEnabled &&
                              _featureSnappingEnabled,
                          onChanged: (allEnabled) {
                            if (allEnabled != null) {
                              _geometryEditor.snapSettings.isEnabled =
                                  allEnabled;
                              _geometryEditor
                                      .snapSettings
                                      .isGeometryGuidesEnabled =
                                  allEnabled;
                              _geometryEditor
                                      .snapSettings
                                      .isFeatureSnappingEnabled =
                                  allEnabled;
                              setState(() {
                                _snappingEnabled = allEnabled;
                                _geometryGuidesEnabled = allEnabled;
                                _featureSnappingEnabled = allEnabled;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                // Add a checkbox to toggle whether snapping is enabled.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Snapping enabled'),
                    Checkbox(
                      value: _snappingEnabled,
                      onChanged: (snappingEnabled) {
                        if (snappingEnabled != null) {
                          _geometryEditor.snapSettings.isEnabled =
                              snappingEnabled;
                          setState(() => _snappingEnabled = snappingEnabled);
                        }
                      },
                    ),
                  ],
                ),
                // Add a checkbox to toggle whether geometry guides are enabled.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Geometry guides'),
                    Checkbox(
                      value: _geometryGuidesEnabled,
                      onChanged: (geometryGuidesEnabled) {
                        if (geometryGuidesEnabled != null) {
                          _geometryEditor.snapSettings.isGeometryGuidesEnabled =
                              geometryGuidesEnabled;
                          setState(
                            () =>
                                _geometryGuidesEnabled = geometryGuidesEnabled,
                          );
                        }
                      },
                    ),
                  ],
                ),
                // Add a checkbox to toggle whether feature snapping is enabled.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Feature snapping'),
                    Checkbox(
                      value: _featureSnappingEnabled,
                      onChanged: (featureSnappingEnabled) {
                        if (featureSnappingEnabled != null) {
                          _geometryEditor
                                  .snapSettings
                                  .isFeatureSnappingEnabled =
                              featureSnappingEnabled;
                          setState(
                            () => _featureSnappingEnabled =
                                featureSnappingEnabled,
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Select snap sources',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Add checkboxes for enabling the point layers as snap sources.
                buildSnapSourcesSelection(
                  'Point layers',
                  _pointLayerSnapSources,
                ),
                // Add checkboxes for the polyline layers as snap sources.
                buildSnapSourcesSelection(
                  'Polyline layers',
                  _polylineLayerSnapSources,
                ),
                // Add checkboxes for the graphics overlay as snap sources.
                buildSnapSourcesSelection(
                  'Graphics Overlay',
                  _graphicsOverlaySnapSources,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSnapSourcesSelection(
    String label,
    List<SnapSourceSettings> allSourceSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                const Text('Enable all'),
                // A checkbox to enable all source settings in the category.
                Checkbox(
                  value: allSourceSettings.every(
                    (snapSourceSettings) => snapSourceSettings.isEnabled,
                  ),
                  onChanged: (allEnabled) {
                    if (allEnabled != null) {
                      allSourceSettings
                          .map(
                            (snapSourceSettings) => setState(
                              () => snapSourceSettings.isEnabled = allEnabled,
                            ),
                          )
                          .toList();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        Column(
          children: allSourceSettings.map((sourceSetting) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display the layer name, or set default text for graphics overlay.
                Text(
                  allSourceSettings == _pointLayerSnapSources ||
                          allSourceSettings == _polylineLayerSnapSources
                      ? (sourceSetting.source as FeatureLayer).name
                      : 'Editor Graphics Overlay',
                ),
                // A checkbox to toggle whether this source setting is enabled.
                Checkbox(
                  value: sourceSetting.isEnabled,
                  onChanged: (isEnabled) {
                    if (isEnabled != null) {
                      setState(() => sourceSetting.isEnabled = isEnabled);
                    }
                  },
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildTSAH(BuildContext context, ref) {
    return Consumer(
      builder: (context, ref, _) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 0),
            color: Theme.of(context).canvasColor.withOpacity(0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll<Color>(Colors.green),
                        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        await buildBottomSheetSettings(context, ref);
                      },
                      child: Text('Tài sản ảnh hưởng', style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll<Color>(Colors.blueAccent),
                        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          ),
                        ),
                      ),
                      onPressed: () {},
                      child: Text('Lưu kết quả', style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll<Color>(Colors.red),
                        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          ),
                        ),
                      ),
                      onPressed: () {
                        clearResult(ref);
                      },
                      child: Text('Xóa', style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ),
                    // Button để toggle editing toolbar
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  List<DropdownMenuItem<GeometryType>> configureGeometryTypeMenuItems() {
    // Create a list of geometry types to make available for editing.
    final geometryTypes = [
      GeometryType.point,
      GeometryType.multipoint,
      GeometryType.polyline,
      GeometryType.polygon,
    ];
    // Returns a list of drop down menu items for each geometry type.
    return geometryTypes
        .map(
          (type) => DropdownMenuItem(
            value: type,
            child: Text(type.name.capitalize()),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem<GeometryEditorTool>> configureToolMenuItems() {
    // Returns a list of drop down menu items for the required tools.
    return [
      DropdownMenuItem(value: _vertexTool, child: const Text('Vertex Tool')),
      DropdownMenuItem(
        value: _reticleVertexTool,
        child: const Text('Reticle Vertex Tool'),
      ),
    ];
  }
  // Method để clear tất cả graphics
  // void clearAllGraphics(Ref ref) {
  //   _graphicsOverlay.graphics.clear();
  //   ref.read(listGeometryProvider.notifier).state = [];
  //   // ref.read(enhancedGeometryDataProvider.notifier).state = [];
  //   //  print("Đã xóa tất cả graphics: ${ref.watch(enhancedGeometryDataProvider)}");
  // }

  // Method để clear graphics với ref để update providers
  void clearAllGraphicsWithRef(WidgetRef ref) {
    _graphicsOverlay.graphics.clear();
    
    // Clear both providers
    ref.read(listGeometryProvider.notifier).state = [];
    ref.read(enhancedGeometryDataProvider.notifier).state = [];

    print("Đã xóa tất cả graphics: ${ref.watch(enhancedGeometryDataProvider)}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa tất cả graphics'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Method để xóa graphic cuối cùng
  void removeLastGraphic() {
    if (_graphicsOverlay.graphics.isNotEmpty) {
      _graphicsOverlay.graphics.removeLast();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa graphic cuối cùng'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }  // Method to project coordinates using portal geocode service (based on ReactJS web version)
  
  Future<int> findObjectIdOngPhanPhoi({
    required double x,
    required double y,
    required SpatialReference inSr,
    required SpatialReference outSR,
    required WidgetRef ref,
  }) async {
    final url = Uri.parse(
      'https://gis.phuwaco.com.vn/server/rest/services/MLCN_PHT/MangLuoiCapNuoc_PHT_V2/FeatureServer/9/query',
    );

    try {
      final token = ref.read(arcgisTokenProvider);

      final geometryPoint = ArcGISPoint(
        x: x,
        y: y,
        spatialReference: inSr,
      ); 
      
      final bufferPolygonForQuery = GeometryEngine.buffer(
        geometry: geometryPoint,
        distance: 1,
      );
      print("=== Buffer Polygon for Query ===");
      print("Buffer Polygon: ${bufferPolygonForQuery.toJson()}");
      print("=================================");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'outFields': 'OBJECTID',
          'f': 'json',
          'token': token ?? '',
          'geometryType': 'esriGeometryPolygon',
          'spatialRel': 'esriSpatialRelIntersects',
          'geometry': json.encode(bufferPolygonForQuery.toJson()),
          'inSR': json.encode(inSr.toJson()),
          'outSR': json.encode(outSR.toJson()),
          'returnGeometry': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] ?? [];
        
        if (features.isNotEmpty) {

          print("=== Found Features ===");
          print("Features: $features");
          print("=======================");
          return features.first['attributes']['OBJECTID'] as int;
        }
      } else if (response.statusCode == 304) {
        print(
          "Content not modified (304) for ID: - trying to use any available data",
        );
      } else {
        final errorMsg = 'Lỗi server: ${response.statusCode}';
        print(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Lỗi: $e';
      print(errorMsg);
    }
    return -1; // Return a default value if no valid OBJECTID is found
  }
  
  Future<Map<String, dynamic>?> projectPointGeometry(
    String url,
    SpatialReference inputSpatialReference,
    SpatialReference outputSpatialReference,
    ArcGISPoint geometry,
    WidgetRef ref,
  ) async {
    try {
      final token = ref.read(arcgisTokenProvider) ?? "";
      
      // Create form data like the ReactJS version
      final formData = <String, String>{
        'inSR': json.encode(inputSpatialReference.toJson()),
        'outSR': json.encode(outputSpatialReference.toJson()),
        'geometries': '${geometry.x},${geometry.y}',
        'transformation': '',
        'transformForward': 'true',
        'vertical': 'false',
        'f': 'pjson',
        'token': token,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("=== Projection Response ===");
        print("Response: $data");
        print("===========================");
        return data;
      } else {
        print("Projection failed with status: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error in portal coordinate projection: $e");
      return null;
    }
  }
  // ================ SHOW BOTTOM SHEET TSAH ================ //
  Future<void> buildBottomSheetSettings(BuildContext context, ref) async {
    final map = widget.controller.arcGISMap;
    if (map == null) return;

    final dataTrace = ref.watch(traceDataProvider);
    final dataHistory = ref.watch(traceHistoryDataProvider);

    // Nếu trace có data → ưu tiên trace
    final data = dataTrace ?? dataHistory;
    final isHistory = dataTrace == null && dataHistory != null;

    // ignore: unused_local_variable
    List<Map<String, dynamic>> vanFields = [];
    // ignore: unused_local_variable
    List<Map<String, dynamic>> dhkhFields = [];

    List<Map<String, dynamic>> vanDieuKhienData = [];
    List<Map<String, dynamic>> dongHoData = [];

    if (vanDieuKhienData.isEmpty && dongHoData.isEmpty) {
      for (final layer in map.operationalLayers) {
        if (layer is FeatureLayer) {
          String ids = '';
          final query = QueryParameters();

          switch (layer.name) {
            case 'Van điều khiển':
              if (isHistory) {
                final idList = (data?['VanAnhHuong'] ?? [])
                    .map((dataId) => dataId['attributes']['IDTaiSan'])
                    .where((id) => id != null && id.toString().isNotEmpty)
                    .map((id) => "'$id'")
                    .join(',');
                if (idList.isEmpty) continue;
                query.whereClause = 'GlobalID IN ($idList)';
              } else {
                ids = (data?['VanAnhHuong'] ?? []).join(',');
                if (ids.isEmpty) continue;
                query.whereClause = 'OBJECTID IN ($ids)';
              }
              break;

            case 'Đồng hồ khách hàng':
              if (isHistory) {
                final idList = (data?['DongHoKhachHang'] ?? [])
                    .map((dataId) => dataId['attributes']['IDTaiSan'])
                    .where((id) => id != null && id.toString().isNotEmpty)
                    .map((id) => "'$id'")
                    .join(',');
                if (idList.isEmpty) continue;
                query.whereClause = 'GlobalID IN ($idList)';
              } else {
                ids = (data?['DongHoKhachHang'] ?? []).join(',');
                if (ids.isEmpty) continue;
                query.whereClause = 'OBJECTID IN ($ids)';
              }
              break;

            default:
              continue;
          }

          // Query và map data
          final result = await layer.featureTable?.queryFeatures(query);
          final features = result?.features() ?? [];
          final fields = layer.featureTable?.fields ?? [];

          final fieldList = fields
              .map((f) => {
                    'name': f.name,
                    'alias': f.alias,
                    'type': f.type.toString(),
                    'domain': f.domain,
                  })
              .toList();

          if (layer.name == 'Van điều khiển') {
            vanDieuKhienData = features.map((f) => f.attributes).toList();
            vanFields = fieldList;
          } else if (layer.name == 'Đồng hồ khách hàng') {
            dongHoData = features.map((f) => f.attributes).toList();
            dhkhFields = fieldList;
          }
        }
      }
    }
    // Gọi hiển thị modal
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // Bấm ra ngoài sẽ đóng
      enableDrag: true, 
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: buildTraceResultTabs(
                    vanDieuKhienData,
                    dongHoData,
                    vanFields,
                    dhkhFields,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget buildTraceResultTabs(
    List<Map<String, dynamic>> vanDieuKhienData,
    List<Map<String, dynamic>> dongHoData,
    List<Map<String, dynamic>> vanFields,
    List<Map<String, dynamic>> dhkhFields,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Van điều khiển'),
              Tab(text: 'Đồng hồ khách hàng'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                buildDataCards(vanDieuKhienData, vanFields),
                buildDataCards(dongHoData, dhkhFields),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget buildDataCards(List<Map<String, dynamic>> data, List<Map<String, dynamic>> fields) {
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    String getFields(String key) {
      final field = fields.toList().where((i) => i['name'] == key).first;
      return field['alias'] ?? key;
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = data[index];

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: row.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text('${getFields(entry.key)}:', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text('${entry.value ?? ''}'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // =============================END====================================//

  // ==================Clear ket qua======================== //
  void clearResult(ref) {
    final map = widget.controller.arcGISMap;
    if (map == null) return;
    for (final layer in map.operationalLayers) {
      if (layer is FeatureLayer) {
        layer.clearSelection();
      }
    }
    // Clear the graphics overlay
    _graphicsOverlay.graphics.clear();
    
    // Clear the enhanced geometry data provider
    ref.read(enhancedGeometryDataProvider.notifier).state = <Map<String, dynamic>>[];
    
    // Clear the list geometry provider
    ref.read(listGeometryProvider.notifier).state = [];

    ref.read(traceDataProvider.notifier).state = null;
    
    // Reset the selected graphic
    _selectedGraphic = null;
    
    // Reset the geometry editor state
    _geometryEditor.stop();
    
    // Reset the geometry editor started flag
    _geometryEditorIsStarted = false;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa kết quả')),
    );}
}
