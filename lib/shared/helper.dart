import 'dart:convert';

import 'package:arcgis_app_demo/config.dart';
import 'package:arcgis_app_demo/core/providers/global_providers.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

void navigateAndClearStack(BuildContext context, String routeName) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (_) => false,
    );
  });
}

// Future<Map<String, dynamic>?> projectPointGeometryRings(
//     String url,
//     SpatialReference inputSpatialReference,
//     SpatialReference outputSpatialReference,
//     Geometry geometry,
//     WidgetRef ref,
//   ) async {
//     try {
//       final token = ref.read(arcgisTokenProvider) ?? "";

//       // Create form data like the ReactJS version
//       final formData = <String, String>{
//         'inSR': json.encode(inputSpatialReference.toJson()),
//         'outSR': json.encode(outputSpatialReference.toJson()),
//         'geometries': geometry.toJson(),
//         'transformation': '',
//         'transformForward': 'true',
//         'vertical': 'false',
//         'f': 'pjson',
//         'token': token,
//       };

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: formData.entries
//             .map(
//               (e) =>
//                   '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
//             )
//             .join('&'),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         print("=== Projection Response ===");
//         print("Response: $data");
//         print("===========================");
//         return data;
//       } else {
//         print("Projection failed with status: ${response.statusCode}");
//         print("Response body: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       print("Error in portal coordinate projection: $e");
//       return null;
//     }
//   }

void selectDMA(String dma, WidgetRef ref) async {
  final token = ref.read(arcgisTokenProvider) ?? '';
  final response = await http.post(
    Uri.parse(ArcGISConfig.dmaUrl),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'where': 'IDDMA = $dma',
      'outFields': 'IDDMA,OBJECTID,TenDMA',
      'f': 'json',
      'token': token,
      'returnGeometry': 'true',
    },
  );

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    print("Geometry ${jsonData['geometry']}");
    final features = jsonData['features'] as List;
    final dma = features.first();

    print("=== Selected DMA ===");
    print("IDDMA: ${dma['attributes']['IDDMA']}");
    print("OBJECTID: ${dma['attributes']['OBJECTID']}");
    print("TenDMA: ${dma['attributes']['TenDMA']}");
  }
}