import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/store_request_detail_entity.dart';

class StoreRequestsState {
  final List<StoreRequestDetail> storeRequests;
  final int total;
  final int page;
  final int pages;
  final bool isLoading;
  final String? error;

  const StoreRequestsState({
    this.storeRequests = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.isLoading = false,
    this.error,
  });

  StoreRequestsState copyWith({
    List<StoreRequestDetail>? storeRequests,
    int? total,
    int? page,
    int? pages,
    bool? isLoading,
    String? error,
  }) {
    return StoreRequestsState(
      storeRequests: storeRequests ?? this.storeRequests,
      total: total ?? this.total,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StoreNotifier extends FamilyAsyncNotifier<StoreRequestsState, String> {
  final _client = NetworkClient();

  @override
  Future<StoreRequestsState> build(String category) => _fetch(category, 1);

  Future<StoreRequestsState> _fetch(String category, int page) async {
    final res = await _client.get(
      '/store/$category',
      queryParameters: {'page': page},
    );
    final data = res.data as Map<String, dynamic>;
    return StoreRequestsState(
      storeRequests: (data['store_requests'] as List)
          .map((e) => StoreRequestDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int,
      page: data['page'] as int,
      pages: data['pages'] as int,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull?.page ?? 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg, current));
  }

  Future<void> goToPage(int page) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg, page));
  }

  Future<bool> approve(String storeRequestId) async {
    try {
      await _client.put('/store/approve/$storeRequestId');
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject(String storeRequestId, String comment) async {
    try {
      await _client.put(
        '/store/reject/$storeRequestId',
        data: {'comment': comment},
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> fulfil(String storeRequestId) async {
    try {
      await _client.put('/store/fulfil/$storeRequestId');
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendChatMessage(String storeRequestId, String message) async {
    try {
      await _client.post(
        '/store/chat/$storeRequestId',
        data: {'message': message},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Usage: ref.watch(storeProvider('pending'))
/// Categories: pending, approved, archive
final storeProvider =
    AsyncNotifierProviderFamily<StoreNotifier, StoreRequestsState, String>(
        StoreNotifier.new);
