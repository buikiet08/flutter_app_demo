import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

final overlayLoadingProvider = StateProvider<bool>((ref) => false);
final featuresProvider = StateProvider<List<dynamic>>((ref) => []);
final errorProvider = StateProvider<String?>((ref) => null);
final usernameProvider = StateProvider<String?>((ref) => null);

// Cache for features by IDVHV to avoid redundant API calls
final featuresCacheProvider = StateProvider<Map<String, List<dynamic>>>((ref) => {});

// Provider to get cached features for a specific IDVHV
final cachedFeaturesProvider = Provider.family<List<dynamic>?, String>((ref, idvhv) {
  final cache = ref.watch(featuresCacheProvider);
  return cache[idvhv];
});

// Provider to check if features are cached for a specific IDVHV
final hasCachedFeaturesProvider = Provider.family<bool, String>((ref, idvhv) {
  final cache = ref.watch(featuresCacheProvider);
  return cache.containsKey(idvhv) && cache[idvhv]!.isNotEmpty;
});

// Logout provider to handle logout functionality
final logoutProvider = Provider<void Function()>((ref) {
  return () {
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();
    ref.read(usernameProvider.notifier).state = null;
    // Clear cache on logout
    ref.read(featuresCacheProvider.notifier).state = {};
  };
});

