import '../../repositories/auth_repository.dart';

class LoginWithGoogle {
  final AuthRepository repository;
  
  LoginWithGoogle(this.repository);

  Future<void> call() async {
    return await repository.login();
  }
}
