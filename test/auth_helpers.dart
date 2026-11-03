import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telefonia_app/data/app_database.dart';
import 'package:telefonia_app/models/user_model.dart';
import 'package:telefonia_app/providers/app_provider.dart';
import 'package:telefonia_app/repositories/telefonia_repository.dart';
import 'package:telefonia_app/repositories/user_repository.dart';
import 'package:telefonia_app/services/password_hasher.dart';

const testPassword = '12345678';
const admin = UserModel(
  id: 'admin-id',
  nome: 'Administrador',
  localTrabalho: 'Central',
  username: 'admin',
  role: 'admin',
);

UserRepository testUsers(AppDatabase database) => UserRepository(
  database,
  // Os testes verificam o fluxo com custo reduzido; produção usa 600 mil iterações.
  hasher: const PasswordHasher(iterations: 1000),
);

Future<AppProvider> loggedAdmin(AppDatabase database) async {
  final users = testUsers(database);
  final provider = AppProvider(
    repository: TelefoniaRepository(database),
    userRepository: users,
  );
  await provider.initialize();
  await provider.login('admin', testPassword);
  return provider;
}

AppDatabase testDatabase({String path = inMemoryDatabasePath}) => AppDatabase(
  factory: databaseFactoryFfi,
  path: path,
  initialAdminHasher: const PasswordHasher(iterations: 1000),
);
