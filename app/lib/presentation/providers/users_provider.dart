import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/user_entity.dart';

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

  Future<bool> updateRole(String userId, String role) async {
    try {
      await _client.put('/users/$userId/update-role', data: {'role': role});
      await fetch(page: state.page);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deactivateUser(String userId) async {
    try {
      await _client.delete('/users/$userId');
      await fetch(page: state.page);
      return true;
    } catch (_) {
      return false;
    }
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
