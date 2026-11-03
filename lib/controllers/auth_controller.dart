import '../models/user_model.dart';
import '../repositories/user_repository.dart';

// A autenticação consulta o banco e compara o hash da senha fornecida com o hash armazenado, garantindo que apenas usuários válidos possam acessar o sistema.
class AuthController {
  AuthController(this.repository);
  final UserRepository repository;
  Future<UserModel?> authenticate(String username, String password) =>
      repository.authenticate(username, password);
}
