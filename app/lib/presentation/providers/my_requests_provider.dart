import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';

class RequestPageState {
  final List<RequestDetail> requests;
  final int total;
  final int page;
  final int pages;
  final bool isLoading;
  final String? error;

  const RequestPageState({
    this.requests = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.isLoading = false,
    this.error,
  });

  RequestPageState copyWith({
    List<RequestDetail>? requests,
    int? total,
    int? page,
    int? pages,
    bool? isLoading,
    String? error,
  }) {
    return RequestPageState(
      requests: requests ?? this.requests,
      total: total ?? this.total,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

RequestPageState _parsePageResponse(Map<String, dynamic> data) {
  return RequestPageState(
    requests: (data['requests'] as List)
        .map((e) => RequestDetail.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: data['total'] as int,
    page: data['page'] as int,
    pages: data['pages'] as int,
    isLoading: false,
  );
}

// --- My Requests Notifier (one per category) ---

class MyRequestsNotifier extends FamilyAsyncNotifier<RequestPageState, String> {
  final _client = NetworkClient();

  @override
  Future<RequestPageState> build(String category) => _fetch(category, 1);

  Future<RequestPageState> _fetch(String category, int page) async {
    final res = await _client.get(
      '/my-requests/$category',
      queryParameters: {'page': page},
    );
    return _parsePageResponse(res.data as Map<String, dynamic>);
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

  /// Create a new request (only used from 'raised' category context)
  Future<bool> createRequest({
    required String mainType,
    required String subType,
    required String description,
    required String roomNo,
  }) async {
    try {
      await _client.post('/my-requests/', data: {
        'main_type': mainType,
        'sub_type': subType,
        'description': description,
        'room_no': roomNo,
      });
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reply to admin (only used from 'replied' category context)
  Future<bool> replyToRequest({
    required String requestId,
    required String comment,
    required String description,
  }) async {
    try {
      await _client.put('/my-requests/reply/$requestId', data: {
        'comment': comment,
        'description': description,
      });
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Usage: ref.watch(myRequestsProvider('raised'))
final myRequestsProvider =
    AsyncNotifierProviderFamily<MyRequestsNotifier, RequestPageState, String>(
        MyRequestsNotifier.new);
