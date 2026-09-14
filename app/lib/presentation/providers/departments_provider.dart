import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/department_entity.dart';

class DepartmentsNotifier extends AsyncNotifier<List<Department>> {
  final _client = NetworkClient();

  @override
  Future<List<Department>> build() => _fetch();

  Future<List<Department>> _fetch() async {
    final res = await _client.get('/departments/');
    return (res.data as List)
        .map((e) => Department.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(String department) async {
    await _client.post('/departments/', data: {'department': department});
    await refresh();
  }

  Future<void> updateDepartment(int id, String department) async {
    await _client.put('/departments/$id', data: {'department': department});
    await refresh();
  }

  Future<void> delete(int id) async {
    await _client.delete('/departments/$id');
    await refresh();
  }
}

final departmentsProvider =
    AsyncNotifierProvider<DepartmentsNotifier, List<Department>>(
        DepartmentsNotifier.new);
