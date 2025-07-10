import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ArcGIS Token Provider
final arcgisTokenProvider = StateProvider<String?>((ref) => null);

// ArcGIS Map Instance Provider
final arcgisMapInstanceProvider = StateProvider<ArcGISMap?>((ref) => null);

// Map Creation Status Provider
final isMapCreatedProvider = StateProvider<bool>((ref) => false);

// History Item Selected Provider
final historyItemSelectedProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Provider to track the last processed history item ID to prevent duplicate processing
final lastProcessedHistoryIdProvider = StateProvider<String?>((ref) => null);

// Helper provider to get the selected history item's ID
final selectedHistoryItemIdProvider = Provider<String?>((ref) {
  final selectedItem = ref.watch(historyItemSelectedProvider);
  return selectedItem?['IDVHV'];
});

// Helper provider to check if any history item is selected
final hasSelectedHistoryItemProvider = Provider<bool>((ref) {
  final selectedItem = ref.watch(historyItemSelectedProvider);  return selectedItem != null;
});

// Active tool providers
final activeToolProvider = StateProvider<bool?>((ref) => false);

/// Enum defining different tool types available in the bottom app bar
/// Each tool represents a different functionality that can be activated
enum ToolType { 
  flag,           // Flag tool (cờ)
  barrier,        // Barrier tool (chướng ngại vật)
}

/// Enum defining operation types
enum OperationType {
  quickOperation,  // Vận hành nhanh - auto execute after placing flag
  normalOperation, // Vận hành thường - manual execute with button
}

/// Provider to track which specific tool button is currently active
/// Only one tool can be active at a time. Setting a new tool automatically
/// deactivates the previous one. Setting null deactivates all tools.
final activeToolButtonProvider = StateProvider<ToolType?>((ref) => null);

/// Provider to track the current operation type
final operationTypeProvider = StateProvider<OperationType>((ref) => OperationType.normalOperation);

/// Helper provider to check if any tool is currently active
final hasActiveToolProvider = Provider<bool>((ref) {
  final activeTool = ref.watch(activeToolButtonProvider);
  return activeTool != null;
});

final listGeometryProvider = StateProvider<List<Geometry>>((ref) => []);

// Provider for enhanced geometry data with tool type and layer info
final enhancedGeometryDataProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => <Map<String, dynamic>>[],
);

final handleTraceTypeProvider = StateProvider<ToolType?>((ref) => null);
final traceDataProvider = StateProvider<Map<String, dynamic>?>((ref) => null);