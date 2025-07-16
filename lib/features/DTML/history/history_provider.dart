import 'package:flutter_riverpod/flutter_riverpod.dart';

// History state providers
// final historyFeaturesProvider = StateProvider<List<dynamic>>((ref) => []);

// final historyLoadingProvider = StateProvider<bool>((ref) => false);

// final historyErrorProvider = StateProvider<String?>((ref) => null);

// final historyPageProvider = StateProvider<int>((ref) => 0);

// final historyPageSizeProvider = StateProvider<int>((ref) => 10);

// final historyHasFetchedProvider = StateProvider<bool>((ref) => false);


// History state model
class HistoryState {
  final List<dynamic> features;
  final List? fields;
  final bool loading;
  final String? error;
  final int page;
  final int pageSize;
  final bool hasFetched;
  final String? selectedItemId;

  const HistoryState({
    this.features = const [],
    this.fields,
    this.loading = false,
    this.error,
    this.page = 0,
    this.pageSize = 10,
    this.hasFetched = false,
    this.selectedItemId,
  });

  HistoryState copyWith({
    List<dynamic>? features,
    List? fields,
    bool? loading,
    String? error,
    int? page,
    int? pageSize,
    bool? hasFetched,
    String? selectedItemId,
  }) {
    return HistoryState(
      features: features ?? this.features,
      fields: fields ?? this.fields,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasFetched: hasFetched ?? this.hasFetched,
      selectedItemId: selectedItemId ?? this.selectedItemId,
    );
  }
}

final historyStateProvider = StateNotifierProvider<HistoryStateNotifier, HistoryState>((ref) {
  return HistoryStateNotifier();
});

class HistoryStateNotifier extends StateNotifier<HistoryState> {
  HistoryStateNotifier() : super(const HistoryState());

  void setFeatures(List<dynamic> features) {
    state = state.copyWith(features: features);
  }

  void setFields(List? fields) {
    // Assuming fields are used in some way, otherwise this can be removed
    state = state.copyWith(fields: fields ?? []);
  }

  void setLoading(bool? loading) {
    state = state.copyWith(loading: loading ?? false);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void setHasFetched(bool hasFetched) {
    state = state.copyWith(hasFetched: hasFetched);
  }

  void setSelectedItemId(String? selectedItemId) {
    state = state.copyWith(selectedItemId: selectedItemId);
  }

  void reset() {
    state = const HistoryState();
  }
}
