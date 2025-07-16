import 'package:arcgis_app_demo/config.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ArcGIS Token Provider
final arcgisTokenProvider = StateProvider<String?>((ref) => null);

final userProvider = StateProvider<PortalUser?>((ref) => null);

final logoutProvider = Provider<void Function()>((ref) {
  return () async {
    ref.read(arcgisTokenProvider.notifier).state = null;
    ref.read(userProvider.notifier).state = null;
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeCredentials(uri: Uri.parse(ArcGISConfig.portalUrl));

    // Xóa tài khoản đã lưu
    final storage = FlutterSecureStorage();
    await storage.deleteAll();
  };
});


// Web Map Provider
final webMapProvider = StateNotifierProvider<WebMapController, Map<String, ArcGISMap>>((ref) {
  return WebMapController();
});

class WebMapController extends StateNotifier<Map<String, ArcGISMap>> {
  WebMapController() : super({});

  void setMap(String appName, ArcGISMap map) {
    state = {...state, appName: map};
  }

  ArcGISMap? getMap(String appName) {
    return state[appName];
  }
}

// DMA
final dmaListProvider = StateProvider<List<String>>((ref) => []);