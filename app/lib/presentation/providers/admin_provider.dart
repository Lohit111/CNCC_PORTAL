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

  Future<String?> deleteRequest(String requestId) async {
    try {
      final response = await _client.delete(
        '/admin/request/$requestId',
      );

      await refresh();

      return response.data['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> deleteStoreRequest(String storeRequestId) async {
    try {
      final response = await _client.delete(
        '/admin/store-request/$storeRequestId',
      );

      await refresh();

      return response.data['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> sendBroadcast(
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    try {
      await _client.post(
        '/notifications/broadcast',
        data: {
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendToRole(
    String role,
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    try {
      await _client.post(
        '/notifications/role',
        data: {
          'role': role,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendToUser(
    String userId,
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    try {
      await _client.post(
        '/notifications/$userId',
        data: {
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
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

// ---------------------------------------------------------------------------
// Search provider
// ---------------------------------------------------------------------------

class AdminSearchNotifier
    extends FamilyAsyncNotifier<List<RequestDetail>, String> {
  final _client = NetworkClient();

  @override
  Future<List<RequestDetail>> build(String prefix) async {
    if (prefix.trim().isEmpty) return [];
    return _search(prefix.trim());
  }

  Future<List<RequestDetail>> _search(String prefix) async {
    final res = await _client.get(
      '/admin/search-prefix',
      queryParameters: {'id': prefix},
    );
    final data = res.data as Map<String, dynamic>;
    return (data['requests'] as List)
        .map((e) => RequestDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Usage: ref.watch(adminSearchProvider(prefix))
/// Pass the current text-field value as the family argument.
final adminSearchProvider =
    AsyncNotifierProviderFamily<AdminSearchNotifier, List<RequestDetail>, String>(
        AdminSearchNotifier.new);

// ---------------------------------------------------------------------------
// Dashboard statistics
// ---------------------------------------------------------------------------

/// A single data point returned by the dashboard endpoint.
class StatPoint {
  final String label; // "YYYY-MM-DD" | "YYYY-MM" | "YYYY"
  final int count;

  const StatPoint({required this.label, required this.count});

  factory StatPoint.fromDailyJson(Map<String, dynamic> j) =>
      StatPoint(label: j['date'] as String, count: j['count'] as int);

  factory StatPoint.fromMonthlyJson(Map<String, dynamic> j) =>
      StatPoint(label: j['month'] as String, count: j['count'] as int);

  factory StatPoint.fromYearlyJson(Map<String, dynamic> j) =>
      StatPoint(label: j['year'] as String, count: j['count'] as int);
}

class DashboardStats {
  final List<StatPoint> daily;   // current month, one entry per day
  final List<StatPoint> monthly; // current year, one entry per month
  final List<StatPoint> yearly;  // all years with data

  const DashboardStats({
    required this.daily,
    required this.monthly,
    required this.yearly,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      daily: (json['daily'] as List)
          .map((e) => StatPoint.fromDailyJson(e as Map<String, dynamic>))
          .toList(),
      monthly: (json['monthly'] as List)
          .map((e) => StatPoint.fromMonthlyJson(e as Map<String, dynamic>))
          .toList(),
      yearly: (json['yearly'] as List)
          .map((e) => StatPoint.fromYearlyJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Filter parameters passed to the dashboard endpoint.
class DashboardFilters {
  final String? idPrefix;
  final String? status;
  final String? roomNo;
  final String? mainType;
  final String? subType;
  final String? raisedBy;

  const DashboardFilters({
    this.idPrefix,
    this.status,
    this.roomNo,
    this.mainType,
    this.subType,
    this.raisedBy,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      if (idPrefix != null && idPrefix!.isNotEmpty) 'id_prefix': idPrefix,
      if (status != null && status!.isNotEmpty) 'status': status,
      if (roomNo != null && roomNo!.isNotEmpty) 'room_no': roomNo,
      if (mainType != null && mainType!.isNotEmpty) 'main_type': mainType,
      if (subType != null && subType!.isNotEmpty) 'sub_type': subType,
      if (raisedBy != null && raisedBy!.isNotEmpty) 'raised_by': raisedBy,
    };
  }

  bool get isEmpty =>
      (idPrefix == null || idPrefix!.isEmpty) &&
      (status == null || status!.isEmpty) &&
      (roomNo == null || roomNo!.isEmpty) &&
      (mainType == null || mainType!.isEmpty) &&
      (subType == null || subType!.isEmpty) &&
      (raisedBy == null || raisedBy!.isEmpty);

  DashboardFilters copyWith({
    Object? idPrefix = _absent,
    Object? status = _absent,
    Object? roomNo = _absent,
    Object? mainType = _absent,
    Object? subType = _absent,
    Object? raisedBy = _absent,
  }) {
    return DashboardFilters(
      idPrefix: idPrefix == _absent ? this.idPrefix : idPrefix as String?,
      status: status == _absent ? this.status : status as String?,
      roomNo: roomNo == _absent ? this.roomNo : roomNo as String?,
      mainType: mainType == _absent ? this.mainType : mainType as String?,
      subType: subType == _absent ? this.subType : subType as String?,
      raisedBy: raisedBy == _absent ? this.raisedBy : raisedBy as String?,
    );
  }
}

const _absent = Object();

class AdminDashboardNotifier
    extends FamilyAsyncNotifier<DashboardStats, DashboardFilters> {
  final _client = NetworkClient();

  @override
  Future<DashboardStats> build(DashboardFilters filters) =>
      _fetch(filters);

  Future<DashboardStats> _fetch(DashboardFilters filters) async {
    final res = await _client.get(
      '/admin/dashboard',
      queryParameters: filters.toQueryParams(),
    );
    return DashboardStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

/// Usage: ref.watch(adminDashboardProvider(DashboardFilters(...)))
final adminDashboardProvider = AsyncNotifierProviderFamily<
    AdminDashboardNotifier, DashboardStats, DashboardFilters>(
  AdminDashboardNotifier.new,
);
