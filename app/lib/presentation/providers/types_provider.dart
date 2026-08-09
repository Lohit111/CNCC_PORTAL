import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';

// --- Main Types ---

class MainTypesNotifier extends AsyncNotifier<List<MainType>> {
  final _client = NetworkClient();

  @override
  Future<List<MainType>> build() => _fetch();

  Future<List<MainType>> _fetch() async {
    final res = await _client.get('/types/main');
    return (res.data as List).map((e) => MainType.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(String name) async {
    await _client.post('/types/main', data: {'name': name});
    await refresh();
  }

  Future<void> updateType(int id, String name) async {
    await _client.put('/types/main/$id', data: {'name': name});
    await refresh();
  }

  Future<void> delete(int id) async {
    await _client.delete('/types/main/$id');
    await refresh();
  }
}

final mainTypesProvider =
    AsyncNotifierProvider<MainTypesNotifier, List<MainType>>(
        MainTypesNotifier.new);

// --- Sub Types ---

class SubTypesNotifier extends FamilyAsyncNotifier<List<SubType>, int> {
  final _client = NetworkClient();

  @override
  Future<List<SubType>> build(int mainTypeId) => _fetch(mainTypeId);

  Future<List<SubType>> _fetch(int mainTypeId) async {
    final res = await _client.get('/types/$mainTypeId/sub');
    return (res.data as List).map((e) => SubType.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> create(String name) async {
    await _client.post('/types/${arg}/sub', data: {'name': name});
    await refresh();
  }

  Future<void> updateSubType(int subId, String name) async {
    await _client.put('/types/sub/$subId', data: {'name': name});
    await refresh();
  }

  Future<void> delete(int subId) async {
    await _client.delete('/types/sub/$subId');
    await refresh();
  }
}

final subTypesProvider =
    AsyncNotifierProviderFamily<SubTypesNotifier, List<SubType>, int>(
        SubTypesNotifier.new);
