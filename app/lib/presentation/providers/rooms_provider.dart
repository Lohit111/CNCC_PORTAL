import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/room_entity.dart';

class RoomsNotifier extends AsyncNotifier<List<Room>> {
  final _client = NetworkClient();

  @override
  Future<List<Room>> build() => _fetch();

  Future<List<Room>> _fetch() async {
    final res = await _client.get('/rooms/');
    return (res.data as List).map((e) => Room.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(String roomNo) async {
    await _client.post('/rooms/', data: {'room_no': roomNo});
    await refresh();
  }

  Future<void> updateRoom(int id, String roomNo) async {
    await _client.put('/rooms/$id', data: {'room_no': roomNo});
    await refresh();
  }

  Future<void> delete(int id) async {
    await _client.delete('/rooms/$id');
    await refresh();
  }
}

final roomsProvider =
    AsyncNotifierProvider<RoomsNotifier, List<Room>>(RoomsNotifier.new);
