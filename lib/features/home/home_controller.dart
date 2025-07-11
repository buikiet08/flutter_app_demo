import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/providers/global_providers.dart';
import 'home_provider.dart';

typedef OnLoginCallback = void Function(String username);
typedef OnLayersReadyCallback = void Function(List<Layer> layers);

enum operationType {
  execute0,
  execute,
  execute1
}

class HomeController implements ArcGISAuthenticationChallengeHandler {
  final ArcGISMapViewController mapViewController =
      ArcGISMapView.createController();
  final Uri portalUri = Uri.parse('https://gis.phuwaco.com.vn/portal');
  final String webMapId = '80de4be9040246e39c82052569d585d3';
  final WidgetRef ref;
  late BuildContext context;
  OnLoginCallback? onLogin;
  OnLayersReadyCallback? onLayersReady;
  // GraphicsOverlay để quản lý markers trên map
  late GraphicsOverlay markersOverlay;
  final _graphicsOverlay = GraphicsOverlay();

  // Other variables
  Timer? _debounceTimer;
  String? _lastProcessedId;

  HomeController(this.ref) {
    // Khởi tạo GraphicsOverlay
    markersOverlay = GraphicsOverlay();
  }
  void initialize(
    BuildContext context, {
    OnLoginCallback? onLogin,
    OnLayersReadyCallback? onLayersReady,
  }) {
    this.context = context;
    this.onLogin = onLogin;
    this.onLayersReady = onLayersReady;
    ArcGISEnvironment
            .authenticationManager
            .arcGISAuthenticationChallengeHandler =
        this;
  }

  void dispose() {
    _debounceTimer?.cancel();
    ArcGISEnvironment
            .authenticationManager
            .arcGISAuthenticationChallengeHandler =
        null;
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();
  }

  Future<void> onHistoryItemSelected() async {
    final selectedItem = ref.read(historyItemSelectedProvider);
    if (selectedItem == null) return;

    final id = selectedItem['IDVHV'] ?? '';

    // Kiểm tra xem ID này đã được xử lý chưa
    if (_lastProcessedId == id) {
      print("Skipping duplicate processing for ID: $id");
      return;
    }

    // Cancel previous timer if exists
    _debounceTimer?.cancel();

    // Debounce để tránh gọi API liên tục
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _processHistoryItem(selectedItem, id);
    });
  }

  Future<void> _processHistoryItem(
    Map<String, dynamic> selectedItem,
    String id,
  ) async {
    if (ref.read(overlayLoadingProvider)) {
      return;
    }

    ref.read(overlayLoadingProvider.notifier).state = true;

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã chọn: $id')));

      // Chỉ gọi fetchFeatures một lần, sau đó xử lý layers
      await fetchFeatures();

      // Kiểm tra xem có features không trước khi xử lý layers
      final features = ref.read(featuresProvider);
      if (features.isNotEmpty) {
        await getListIdsOperationalLayers();
        _lastProcessedId = id; // Mark this ID as processed
      }
    } catch (e) {
      ref.read(errorProvider.notifier).state = 'Lỗi xử lý: $e';
    } finally {
      ref.read(overlayLoadingProvider.notifier).state = false;
    }
  } // Track ongoing requests to prevent duplicates

  static final Map<String, Future<void>> _ongoingRequests = {};

  Future<void> fetchFeatures({int page = 0}) async {
    final selectedItem = ref.read(historyItemSelectedProvider);
    final id = selectedItem?['IDVHV'] ?? '';

    // Kiểm tra nếu không có ID thì không gọi API
    if (id.isEmpty) {
      print("No IDVHV found, skipping API call");
      return;
    }

    // Create a unique key for this request
    final requestKey = 'fetchFeatures_$id';

    // Check if this request is already ongoing
    if (_ongoingRequests.containsKey(requestKey)) {
      print("Request already in progress for ID: $id, waiting...");
      await _ongoingRequests[requestKey];
      return;
    }

    // Tránh gọi API nếu đã đang loading
    // if (ref.read(overlayLoadingProvider)) {
    //   print("API call skipped - already loading");
    //   return;
    // }

    // Create and store the request future
    final requestFuture = _performFetchFeatures(id, page);
    _ongoingRequests[requestKey] = requestFuture;

    try {
      await requestFuture;
    } finally {
      // Clean up the ongoing request
      _ongoingRequests.remove(requestKey);
    }
  }

  Future<void> _performFetchFeatures(String id, int page) async {
    ref.read(overlayLoadingProvider.notifier).state = true;
    ref.read(errorProvider.notifier).state = null;

    // Check cache first
    final cachedFeatures = ref.read(cachedFeaturesProvider(id));
    if (cachedFeatures != null && cachedFeatures.isNotEmpty) {
      ref.read(featuresProvider.notifier).state = cachedFeatures;
      ref.read(overlayLoadingProvider.notifier).state = false;
      return;
    }

    final url = Uri.parse(
      'https://gis.phuwaco.com.vn/server/rest/services/VANHANHVAN/GIS_PHT_VANHANHVAN/FeatureServer/1/query',
    );

    try {
      final token = ref.read(arcgisTokenProvider);

      // Thêm timestamp để tránh caching (304 status)
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
        body: {
          'where': "IDVHV = '$id'",
          'outFields': '*',
          'f': 'json',
          'token': token ?? '',
          'returnGeometry': 'false',
          '_ts': timestamp.toString(), // Cache busting parameter
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] ?? [];
        // Update both current features and cache
        ref.read(featuresProvider.notifier).state = features;

        // Store in cache
        final currentCache = ref.read(featuresCacheProvider);
        ref.read(featuresCacheProvider.notifier).state = {
          ...currentCache,
          id: features,
        };
      } else if (response.statusCode == 304) {
        print(
          "Content not modified (304) for ID: $id - trying to use any available data",
        );
      } else {
        final errorMsg = 'Lỗi server: ${response.statusCode}';
        ref.read(errorProvider.notifier).state = errorMsg;
      }
    } catch (e) {
      final errorMsg = 'Lỗi: $e';
      ref.read(errorProvider.notifier).state = errorMsg;
    } finally {
      ref.read(overlayLoadingProvider.notifier).state = false;
    }
  }

  Future<void> getListIdsOperationalLayers() async {
    final features = ref.read(featuresProvider);

    if (features.isEmpty) {
      print("No features available to extract IDs.");
      return;
    }

    // Kiểm tra xem map đã sẵn sàng chưa
    if (mapViewController.arcGISMap?.operationalLayers.isEmpty ?? true) {
      print("Map layers not ready yet.");
      return;
    }

    try {
      final dataVanIds = features.where((f) => f['attributes']['IDLayer'] == 5);
      final dataDongHoIds = features.where(
        (f) => f['attributes']['IDLayer'] == 7,
      );
      final dataOPPIds = features.where((f) => f['attributes']['IDLayer'] == 9);
      final dataONIds = features.where((f) => f['attributes']['IDLayer'] == 10);

      ref.read(traceHistoryDataProvider.notifier).state = {
        'VanAnhHuong': dataVanIds,
        'VanDong': dataVanIds,
        'OngPhanPhoi': dataOPPIds,
        'OngNganh': dataONIds,
        'DongHoKhachHang': dataDongHoIds,
      };

      mapViewController.arcGISMap?.operationalLayers.forEach((layer) {
        if (layer is FeatureLayer) {
          final query = QueryParameters();

          switch (layer.name) {
            case "Van điều khiển":
              if (dataVanIds.isNotEmpty) {
                selectToLayer(layer, dataVanIds.toList(), query);
              }
              break;
            case "Đồng hồ khách hàng":
              if (dataDongHoIds.isNotEmpty) {
                selectToLayer(layer, dataDongHoIds.toList(), query);
              }
              break;
            case "Ống phân phối":
              if (dataOPPIds.isNotEmpty) {
                selectToLayer(layer, dataOPPIds.toList(), query);
              }
              break;
            case "Ống ngánh":
              if (dataONIds.isNotEmpty) {
                selectToLayer(layer, dataONIds.toList(), query);
              }
              break;
            default:
              print("Unknown layer: ${layer.name}");
          }
        }
      });
    } catch (e) {
      print("Error processing operational layers: $e");
    }
  }

  void selectToLayer(FeatureLayer layer, List data, QueryParameters query) {
    if (data.isEmpty) {
      print("No data to select for layer: ${layer.name}");
      return;
    }

    try {
      // Clear selection for all layers first
      mapViewController.arcGISMap?.operationalLayers.forEach((layer) {
        if (layer is FeatureLayer) {
          layer.clearSelection();
        }
      });

      // Tạo WhereClause an toàn
      final idList = data
          .map((dataId) => dataId['attributes']['IDTaiSan'])
          .where((id) => id != null && id.toString().isNotEmpty)
          .map((id) => "'$id'")
          .join(',');

      if (idList.isEmpty) {
        return;
      }

      query.whereClause = 'GlobalID IN ($idList)';

      // Select features with query
      layer
          .selectFeaturesWithQuery(parameters: query, mode: SelectionMode.new_)
          .then((featureQueryResult) async {
            final features = featureQueryResult.features();

            if (features.isEmpty) {
              print("No features found matching the query for ${layer.name}");
              return;
            }

            // Calculate bounding box for zoom
            double? xmin, ymin, xmax, ymax;
            SpatialReference? sr;

            for (var f in features) {
              final geom = f.geometry;
              if (geom != null) {
                final json = geom.toJson();
                sr ??= geom.spatialReference;
                if (json['x'] != null && json['y'] != null) {
                  final x = json['x'] as double;
                  final y = json['y'] as double;
                  xmin = xmin == null ? x : (x < xmin ? x : xmin);
                  xmax = xmax == null ? x : (x > xmax ? x : xmax);
                  ymin = ymin == null ? y : (y < ymin ? y : ymin);
                  ymax = ymax == null ? y : (y > ymax ? y : ymax);
                }
              }
            }

            if (xmin != null && ymin != null && xmax != null && ymax != null) {
              final envelope = Envelope.fromXY(
                xMin: xmin,
                yMin: ymin,
                xMax: xmax,
                yMax: ymax,
                spatialReference: sr ?? SpatialReference.wgs84,
              );

              await mapViewController.setViewpointGeometry(
                envelope,
                paddingInDiPs: 20,
              );
            }
          })
          .catchError((error) {
            print("Error selecting features for ${layer.name}: $error");
          });
    } catch (e) {
      print("Error in selectToLayer for ${layer.name}: $e");
    }
  }

  Future<void> logout() async {
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();
    ref.read(usernameProvider.notifier).state = null;
  }
  
  Future<void> onMapViewReady() async {
    final map = ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal(portalUri, connection: PortalConnection.authenticated),
        itemId: webMapId,
      ),
    );

    // Set feature tiling mode để hỗ trợ snapping
    // Snapping được sử dụng để duy trì tính toàn vẹn dữ liệu giữa các nguồn dữ liệu khác nhau khi chỉnh sửa,
    // vì vậy cần độ phân giải đầy đủ để snapping hợp lệ.
    map.loadSettings.featureTilingMode =
        FeatureTilingMode.enabledWithFullResolutionWhenSupported;    // Set map to map view controller
    mapViewController.arcGISMap = map;

    // Note: Graphics overlay được quản lý bởi MapViewWidget
    // mapViewController.graphicsOverlays.add(markersOverlay);

    // Load map và tất cả layers để synchronize snap settings
    await map.load();
    await mapViewController.setViewpointScale(20000);

    // Đảm bảo map và mỗi layer được load để synchronize snap settings
    // final query = QueryParameters();
    // query.returnGeometry = true;
    // await Future.wait(map.operationalLayers.map((layer) => layer.load()));

    ref.read(arcgisMapInstanceProvider.notifier).state = map;
    ref.read(isMapCreatedProvider.notifier).state = true;
  }

  Future<void> onMapViewTap(Offset screenPoint) async {
    final map = mapViewController.arcGISMap;
    if (map == null) return;

    // Clear selection on all layers
    final layers = map.operationalLayers
        .whereType<FeatureLayer>()
        .toList()
        .reversed
        .toList();
    for (var layer in layers) {
      layer.clearSelection();
    }
    // Kiểm tra xem có active tool button nào không
    final activeButton = ref.watch(activeToolProvider);
    // ignore: unrelated_type_equality_checks
    if (activeButton == true) {
      // Nếu có active tool, không thực hiện identify
      return;
    }

    // Legacy logic for identify feature khi tap vào map
    ref.read(overlayLoadingProvider.notifier).state = true;
    if (layers.isEmpty) return;
    const double tolerance = 10.0;
    for (final layer in layers) {
      final result = await mapViewController.identifyLayer(
        layer,
        screenPoint: screenPoint,
        tolerance: tolerance,
        maximumResults: 1,
      );
      if (result.geoElements.isNotEmpty) {
        final feature = result.geoElements.first;
        final attributes = feature.attributes;
        // Highlight feature
        if (feature is Feature) {
          layer.selectFeature(feature);
        }

        final layerName = layer.name;
        // ignore: use_build_context_synchronously
        final deviceHeight = MediaQuery.of(context).size.height;

        showModalBottomSheet(
          constraints: BoxConstraints(maxHeight: deviceHeight * 0.6),
          // ignore: use_build_context_synchronously
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed title
                Text(
                  layerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder.all(color: Colors.grey, width: 0.7),
                      children: attributes.entries
                          .map(
                            (e) => TableRow(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                    horizontal: 4.0,
                                  ),
                                  child: Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                    horizontal: 4.0,
                                  ),
                                  child: Text(
                                    e.value?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Fixed button at bottom
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        break;
      }
    }
    ref.read(overlayLoadingProvider.notifier).state = false;
  }

  Future<void> onActiveToolChanged(bool isActive) async {
    // Cập nhật trạng thái active tool
    ref.read(activeToolProvider.notifier).state = isActive;
    if (isActive) {
      // Nếu active tool được bật, có thể thực hiện các hành động cần thiết
      mapViewController.arcGISMap?.operationalLayers.forEach((layer) {
        if (layer is FeatureLayer) {
          layer.clearSelection();
        }
      });
    } else {
      // Nếu active tool được tắt, có thể thực hiện các hành động cần thiết
      print("Active tool disabled");
    }
  }
  
  @override
  Future<void> handleArcGISAuthenticationChallenge(
    ArcGISAuthenticationChallenge challenge,
  ) async {
    // Tự động đăng nhập với tài khoản mặc định
    try {
      final credential = await TokenCredential.createWithChallenge(
        challenge,
        username: 'intelli.dev',
        password: 'Intelli.dev.2024',
      );
      credential.getTokenInfo().then((info) {
        ref.read(arcgisTokenProvider.notifier).state = info.accessToken;
      });
      if (onLogin != null) onLogin!('intelli.dev');
      challenge.continueWithCredential(credential);
    } on ArcGISException catch (_) {
      challenge.continueAndFail();
    }  }

  /// Xử lý trace network analysis sử dụng HTTP requests
  Future<void> executeTraceOperation() async {
    print("Starting _executeTraceOperation");
    try {
      // Get enhanced geometry data
      final enhancedData = ref.read(enhancedGeometryDataProvider);
      print("Found ${enhancedData.length} enhanced geometries for trace operation");
      
      if (enhancedData.isEmpty) {
        print("No geometries found, showing warning message");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng chấm điểm trước khi thực hiện vận hành'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Separate flags and barriers
      final List<Map<String, dynamic>> flags = [];
      final List<Map<String, dynamic>> barriers = [];
      
      for (final data in enhancedData) {
        final toolType = data['toolType'] as ToolType;
        final x = data['x'] as double;
        final y = data['y'] as double;
        // final loaiOng = data['loaiOng'] as String; // Currently not used in trace
        final objectId = data['objectId'] as int;
        
        final pointData = {
          "ObjectId": objectId,
          "X": x,
          "Y": y,
          "LoaiOng": "OngPhanPhoi",
        };
        
        if (toolType == ToolType.flag) {
          flags.add(pointData);
        } else if (toolType == ToolType.barrier) {
          barriers.add(pointData);
        }
      }
      
      print("Prepared ${flags.length} flags and ${barriers.length} barriers");
      
      // Call new trace API
      await _callNewTraceAPI(flags: flags, barriers: barriers);
      
    } catch (e) {
      print("Error in _executeTraceOperation: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thực hiện vận hành: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Call new trace API
  Future<void> _callNewTraceAPI({
    required List<Map<String, dynamic>> flags,
    required List<Map<String, dynamic>> barriers,
  }) async {
    final map = mapViewController.arcGISMap;
    if (map == null) return;
    
    print("Calling new trace API with ${flags.length} flags and ${barriers.length} barriers");
    
    ref.read(overlayLoadingProvider.notifier).state = true;

    try {
      final url = Uri.parse('https://iotplatform.intelli.com.vn/API_PHT/Trace');
      
      final requestBody = {
        "Flag": flags,
        "Barrier": barriers,
        "ValveBarrier": [],
        "Source": []
      };
      
      print("Request body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${ref.read(arcgisTokenProvider)}'},
        body: jsonEncode(requestBody).toString(),
      );

      if (response.statusCode == 200) {
        print('Trace API response: ${response.body}');
        
        final responseData = json.decode(response.body);
        await _processTraceResults(responseData['data'] ?? {});
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vận hành đã được thực hiện thành công'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('Trace API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi API: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
    } catch (e) {
      print("Error calling trace API: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gọi API trace: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(overlayLoadingProvider.notifier).state = false;
    }
  }

  /// Process trace results and highlight affected features
  Future<void> _processTraceResults(Map<String, dynamic> responseData) async {
    final map = mapViewController.arcGISMap;
    if (map == null) return;
    
    try {
      // Clear previous selections
      for (final layer in map.operationalLayers) {
        if (layer is FeatureLayer) {
          layer.clearSelection();
        }
      }
      
      // Extract IDs from response
      // Assuming the response contains arrays of IDs for different layer types
      final vanAnhHuongIds = (responseData['VanAnhHuong'] as List?)?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList() ?? <int>[];
      final vanDongIds = (responseData['VanDong'] as List?)?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList() ?? <int>[];
      final oppIds = (responseData['OngPhanPhoi'] as List?)?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList() ?? <int>[];
      final onIds = (responseData['OngNganh'] as List?)?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList() ?? <int>[];
      final dhkhIds = (responseData['DongHoKhachHang'] as List?)?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList() ?? <int>[];
      

      ref.read(traceDataProvider.notifier).state = {
        'VanAnhHuong': vanAnhHuongIds,
        'VanDong': vanDongIds,
        'OngPhanPhoi': oppIds,
        'OngNganh': onIds,
        'DongHoKhachHang': dhkhIds,
      };

      // Highlight affected features
      if (vanAnhHuongIds.isNotEmpty) {
        await _selectFeaturesInLayer("Van điều khiển", vanAnhHuongIds.map((id) => id.toString()).toList());
      }

      if (vanDongIds.isNotEmpty) {
        await _selectFeaturesInLayer("Van điều khiển", vanDongIds.map((id) => id.toString()).toList());
      }
      
      if (oppIds.isNotEmpty) {
        await _selectFeaturesInLayer("Ống phân phối", oppIds.map((id) => id.toString()).toList());
      }
      
      if (onIds.isNotEmpty) {
        await _selectFeaturesInLayer("Ống ngánh", onIds.map((id) => id.toString()).toList());
      }

      if (dhkhIds.isNotEmpty) {
        await _selectFeaturesInLayer("Đồng hồ khách hàng", dhkhIds.map((id) => id.toString()).toList());
      }

      resetActiveTool();
      
      print("Successfully highlighted affected features");
      
    } catch (e) {
      print("Error processing trace results: $e");
    }
  }

  /// Select features in a specific layer by IDs
  Future<void> _selectFeaturesInLayer(String layerName, List<String> ids) async {
    final map = mapViewController.arcGISMap;
    if (map == null) return;
    
    try {
      final layer = map.operationalLayers
          .whereType<FeatureLayer>()
          .firstWhere((l) => l.name == layerName);
      
      final query = QueryParameters();
      final idList = ids.map((id) => id).join(',');
      query.whereClause = 'OBJECTID IN ($idList)';
      
      await layer.selectFeaturesWithQuery(
        parameters: query,
        mode: SelectionMode.new_,
      )
      .then((featureQueryResult) async {
        final features = featureQueryResult.features();

        if (features.isEmpty) {
          print("No features found matching the query for ${layer.name}");
          return;
        }

        // Calculate bounding box for zoom
        double? xmin, ymin, xmax, ymax;
        SpatialReference? sr;

        for (var f in features) {
          final geom = f.geometry;
          if (geom != null) {
            final json = geom.toJson();
            sr ??= geom.spatialReference;
            if (json['x'] != null && json['y'] != null) {
              final x = json['x'] as double;
              final y = json['y'] as double;
              xmin = xmin == null ? x : (x < xmin ? x : xmin);
              xmax = xmax == null ? x : (x > xmax ? x : xmax);
              ymin = ymin == null ? y : (y < ymin ? y : ymin);
              ymax = ymax == null ? y : (y > ymax ? y : ymax);
            }
          }
        }

        if (xmin != null && ymin != null && xmax != null && ymax != null) {
          final envelope = Envelope.fromXY(
            xMin: xmin,
            yMin: ymin,
            xMax: xmax,
            yMax: ymax,
            spatialReference: sr ?? SpatialReference.wgs84,
          );

          await mapViewController.setViewpointGeometry(
            envelope,
            paddingInDiPs: 30,
          );
        }
      })
      .catchError((error) {
        print("Error selecting features for ${layer.name}: $error");
      });
    } catch (e) {
      print("Error selecting features in layer $layerName: $e");
    }
  }

  void resetActiveTool() {
    ref.read(activeToolButtonProvider.notifier).state = null;
    ref.read(activeToolProvider.notifier).state = false;
    ref.read(operationTypeProvider.notifier).state = OperationType.normalOperation;
    _graphicsOverlay.graphics.clear();
    // Clear both providers
    // ref.read(listGeometryProvider.notifier).state = [];
    // ref.read(enhancedGeometryDataProvider.notifier).state = [];
  }
}
