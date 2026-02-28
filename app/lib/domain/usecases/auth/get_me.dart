import '../../repositories/auth_repository.dart';

class GetMe {
  final AuthRepository repository;
  
  GetMe(this.repository);

  Future<Map<String, dynamic>> call() async {
    return await repository.getMe();
  }
}
