import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';

class AdminRequestsState {
  final List<RequestDetail> requests;
  final int total;
  final int page;
  final int pages;
  final bool isLoading;
  final String? error;

  const AdminRequestsState({
    this.requests = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.isLoading = false,
    this.error,
  });

  AdminRequestsState copyWith({
    List<RequestDetail>? requests,
    int? total,
    int? page,
    int? pages,
    bool? isLoading,
    String? error,
  }) {
    return AdminRequestsState(
      requests: requests ?? this.requests,
      total: total ?? this.total,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends FamilyAsyncNotifier<AdminRequestsState, String> {
  final _client = NetworkClient();

  @override
  Future<AdminRequestsState> build(String category) => _fetch(category, 1);

  Future<AdminRequestsState> _fetch(String category, int page) async {
    final res = await _client.get(
      '/admin/$category',
      queryParameters: {'page': page},
    );
    final data = res.data as Map<String, dynamic>;
    return AdminRequestsState(
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

  Future<bool> reply(String requestId, String comment) async {
    try {
      await _client.put('/admin/reply/$requestId', data: {'comment': comment});
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assign(String requestId, List<String> staffIds) async {
    try {
      await _client
          .put('/admin/assign/$requestId', data: {'staff_ids': staffIds});
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject(String requestId, String comment) async {
    try {
      await _client.put('/admin/reject/$requestId', data: {'comment': comment});
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    try {
      await _client.delete('/admin/request/$requestId');
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteStoreRequest(String storeRequestId) async {
    try {
      await _client.delete('/admin/store-request/$storeRequestId');
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Usage: ref.watch(adminProvider('raised'))
/// Categories: raised, replied, assigned, reassign-requested, inprogress, archive
final adminProvider =
    AsyncNotifierProviderFamily<AdminNotifier, AdminRequestsState, String>(
        AdminNotifier.new);
