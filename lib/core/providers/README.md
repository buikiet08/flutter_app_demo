# Migration from Global State to Riverpod Providers

## Overview
The global state variables have been migrated from `lib/global.dart` to Riverpod providers in `lib/core/providers/global_providers.dart`.

## Migration Mapping

### Before (global.dart)
```dart
String? globalArcGISToken;
ArcGISMap? globalMapInstance;
bool? isMapCreated = false;
ValueNotifier<Map<String, dynamic>?> historyItemSelectedNotifier = ValueNotifier(null);
```

### After (core/providers/global_providers.dart)
```dart
final arcgisTokenProvider = StateProvider<String?>((ref) => null);
final arcgisMapInstanceProvider = StateProvider<ArcGISMap?>((ref) => null);
final isMapCreatedProvider = StateProvider<bool>((ref) => false);
final historyItemSelectedProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
```

## How to Use the New Providers

### 1. Reading Values
```dart
// Before
final token = globalArcGISToken;

// After (in a ConsumerWidget or with WidgetRef)
final token = ref.read(arcgisTokenProvider);
final token = ref.watch(arcgisTokenProvider); // For reactive updates
```

### 2. Setting Values
```dart
// Before
globalArcGISToken = 'new_token';

// After
ref.read(arcgisTokenProvider.notifier).state = 'new_token';
```

### 3. Listening to Changes
```dart
// Before
historyItemSelectedNotifier.addListener(callback);

// After (in initState or similar)
ref.listen<Map<String, dynamic>?>(historyItemSelectedProvider, (previous, next) {
  if (next != null) {
    callback();
  }
});
```

## Additional Helper Providers

### Selected History Item ID
```dart
final selectedHistoryItemIdProvider = Provider<String?>((ref) {
  final selectedItem = ref.watch(historyItemSelectedProvider);
  return selectedItem?['IDVHV'];
});
```

### Has Selected History Item
```dart
final hasSelectedHistoryItemProvider = Provider<bool>((ref) {
  final selectedItem = ref.watch(historyItemSelectedProvider);
  return selectedItem != null;
});
```

## Updated Files

### Controllers Updated:
- `lib/features/home/home_controller.dart` - Now uses Riverpod providers
- `lib/features/history/history_controller.dart` - Now uses Riverpod providers

### Key Changes:
1. Removed dependency on `lib/global.dart`
2. Added import for `lib/core/providers/global_providers.dart`
3. Changed all global variable references to use `ref.read()` or `ref.watch()`
4. Replaced `historyItemSelectedNotifier.value = X` with `ref.read(historyItemSelectedProvider.notifier).state = X`
5. Replaced `historyItemSelectedNotifier.addListener()` with `ref.listen()`

## Benefits of This Migration

1. **Type Safety**: Riverpod provides compile-time type safety
2. **Dependency Injection**: Easy to test and mock providers
3. **Reactive Updates**: Widgets automatically rebuild when state changes
4. **Better Performance**: Only widgets that depend on specific state rebuild
5. **Debugging**: Better DevTools support for state inspection
6. **Scoped State**: Can override providers for testing or different app configurations

## Next Steps

1. You can now remove the `lib/global.dart` file if it's no longer used
2. Consider moving any remaining global state to Riverpod providers
3. Test the app to ensure all functionality works correctly with the new state management
