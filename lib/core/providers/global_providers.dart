import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ArcGIS Token Provider
final arcgisTokenProvider = StateProvider<String?>((ref) => null);

final userProvider = StateProvider<PortalUser?>((ref) => null);