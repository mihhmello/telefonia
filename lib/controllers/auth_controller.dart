import '../models/user_model.dart';
import '../repositories/user_repository.dart';

// A autenticação consulta o banco e compara o hash; não há contas fixas.
class AuthController {
  AuthController(this.repository);
  final UserRepository repository;
  Future<UserModel?> authenticate(String username, String password) =>
      repository.authenticate(username, password);
}
