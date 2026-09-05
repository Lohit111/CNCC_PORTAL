import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/user_entity.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/store_request_entity.dart';

// ---------------------------------------------------------------------------
// Participation conflict — four lists of entities
// ---------------------------------------------------------------------------

class UserParticipation {
  final List<Request> raisedRequests;
  final List<Request> assignedRequests;
  final List<StoreRequest> requestedStoreRequests;
  final List<StoreRequest> respondedStoreRequests;

  const UserParticipation({
    required this.raisedRequests,
    required this.assignedRequests,
    required this.requestedStoreRequests,
    required this.respondedStoreRequests,
  });

  factory UserParticipation.fromJson(Map<String, dynamic> p) {
    List<Request> toRequests(String key) => ((p[key] as List?) ?? [])
        .map((e) => Request.fromJson(e as Map<String, dynamic>))
        .toList();

    List<StoreRequest> toStoreRequests(String key) => ((p[key] as List?) ?? [])
        .map((e) => StoreRequest.fromJson(e as Map<String, dynamic>))
        .toList();

    return UserParticipation(
      raisedRequests: toRequests('raised_requests'),
      assignedRequests: toRequests('assigned_requests'),
      requestedStoreRequests: toStoreRequests('requested_store_requests'),
      respondedStoreRequests: toStoreRequests('responded_store_requests'),
    );
  }

  bool get isEmpty =>
      raisedRequests.isEmpty &&
      assignedRequests.isEmpty &&
      requestedStoreRequests.isEmpty &&
      respondedStoreRequests.isEmpty;
}

// ---------------------------------------------------------------------------
// Action result — success, participation conflict, or plain error
// ---------------------------------------------------------------------------

class UserActionResult {
  final bool success;
  final UserParticipation? conflict;
  final String? error;

  const UserActionResult.ok()
      : success = true,
        conflict = null,
        error = null;

  const UserActionResult.conflict(this.conflict)
      : success = false,
        error = null;

  const UserActionResult.error(this.error)
      : success = false,
        conflict = null;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UsersState {
  final List<User> users;
  final int total;
  final int page;
  final int pages;
  final bool isLoading;
  final String? error;

  const UsersState({
    this.users = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.isLoading = false,
    this.error,
  });

  UsersState copyWith({
    List<User>? users,
    int? total,
    int? page,
    int? pages,
    bool? isLoading,
    String? error,
  }) {
    return UsersState(
      users: users ?? this.users,
      total: total ?? this.total,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UsersNotifier extends StateNotifier<UsersState> {
  final _client = NetworkClient();

  UsersNotifier() : super(const UsersState(isLoading: true)) {
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get('/users/', queryParameters: {'page': page});
      final data = res.data as Map<String, dynamic>;
      state = UsersState(
        users: (data['users'] as List).map((e) => User.fromJson(e)).toList(),
        total: data['total'] as int,
        page: data['page'] as int,
        pages: data['pages'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createUser(String email, String role) async {
    try {
      await _client.post('/users/', data: {'email': email, 'role': role});
      await fetch(page: state.page);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserActionResult> updateRole(String userId, String role) async {
    try {
      await _client.put('/users/$userId/update-role', data: {'role': role});
      await fetch(page: state.page);
      return const UserActionResult.ok();
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return UserActionResult.error(e.toString());
    }
  }

  Future<UserActionResult> deactivateUser(String userId) async {
    try {
      await _client.delete('/users/$userId');
      await fetch(page: state.page);
      return const UserActionResult.ok();
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return UserActionResult.error(e.toString());
    }
  }

  UserActionResult _handleError(DioException e) {
    final data = e.response?.data;
    if (e.response?.statusCode == 409 && data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is Map<String, dynamic> &&
          detail.containsKey('participation')) {
        return UserActionResult.conflict(
          UserParticipation.fromJson(
              detail['participation'] as Map<String, dynamic>),
        );
      }
    }
    // Extract a readable message from any error shape
    String msg = 'Action failed.';
    if (data is Map && data['detail'] is String) {
      msg = data['detail'] as String;
    } else if (e.message != null && e.message!.isNotEmpty) {
      msg = e.message!;
    }
    return UserActionResult.error(msg);
  }

  Future<void> nextPage() async {
    if (state.page < state.pages) await fetch(page: state.page + 1);
  }

  Future<void> prevPage() async {
    if (state.page > 1) await fetch(page: state.page - 1);
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  return UsersNotifier();
});
