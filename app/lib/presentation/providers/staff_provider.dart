import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';
import 'package:cncc_portal/domain/entities/store_chat_entity.dart';

class StaffRequestsState {
  final List<RequestDetail> requests;
  final int total;
  final int page;
  final int pages;
  final bool isLoading;
  final String? error;

  const StaffRequestsState({
    this.requests = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.isLoading = false,
    this.error,
  });

  StaffRequestsState copyWith({
    List<RequestDetail>? requests,
    int? total,
    int? page,
    int? pages,
    bool? isLoading,
    String? error,
  }) {
    return StaffRequestsState(
      requests: requests ?? this.requests,
      total: total ?? this.total,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StaffNotifier extends FamilyAsyncNotifier<StaffRequestsState, String> {
  final _client = NetworkClient();

  @override
  Future<StaffRequestsState> build(String category) => _fetch(category, 1);

  Future<StaffRequestsState> _fetch(String category, int page) async {
    final res = await _client.get(
      '/staff/$category',
      queryParameters: {'page': page},
    );
    final data = res.data as Map<String, dynamic>;
    return StaffRequestsState(
      requests: (data['requests'] as List)
          .map((e) => RequestDetail.fromJson(e as Map<String, dynamic>))
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

  Future<bool> startRequest(String requestId) async {
    try {
      await _client.put('/staff/start-request/$requestId');
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestReassignment(String requestId, String comment) async {
    try {
      await _client.put(
        '/staff/request-reassignment/$requestId',
        data: {'comment': comment},
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> finishRequest(String requestId) async {
    try {
      await _client.put('/staff/finish-request/$requestId');
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createStoreRequest(String requestId, String description) async {
    try {
      await _client.put(
        '/staff/create-store-request/$requestId',
        data: {'description': description},
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Usage: ref.watch(staffProvider('assigned'))
/// Categories: assigned, inprogress, archive
final staffProvider =
    AsyncNotifierProviderFamily<StaffNotifier, StaffRequestsState, String>(
        StaffNotifier.new);

// --- Store Chat ---

class StoreChatNotifier extends FamilyAsyncNotifier<List<StoreChat>, String> {
  final _client = NetworkClient();

  @override
  Future<List<StoreChat>> build(String storeRequestId) =>
      _fetch(storeRequestId);

  Future<List<StoreChat>> _fetch(String storeRequestId) async {
    final res = await _client.get('/staff/chat/$storeRequestId');
    return (res.data as List)
        .map((e) => StoreChat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

/// Usage: ref.watch(storeChatProvider(storeRequestId))
final storeChatProvider =
    AsyncNotifierProviderFamily<StoreChatNotifier, List<StoreChat>, String>(
        StoreChatNotifier.new);
