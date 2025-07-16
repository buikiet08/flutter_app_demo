import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Thiết lập license
  ArcGISEnvironment.setLicenseUsingKey(
    "AAPK31c7da9ee4eb43a395dc20d110bbc40601aK0jW85CCumWqiPqjSsTErW_HnZwr-iug4IuGrZLc_RO01Bmf7LC-30opiKpz4",
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}


