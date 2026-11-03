import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telefonia_app/data/app_database.dart';
import 'package:telefonia_app/models/user_model.dart';
import 'package:telefonia_app/models/contrato_model.dart';
import 'package:telefonia_app/repositories/crud_repository.dart';
import 'package:telefonia_app/repositories/user_repository.dart';
import 'package:telefonia_app/services/password_hasher.dart';

import 'auth_helpers.dart';

const viewer = UserModel(
  id: 'viewer-id',
  nome: 'Maria',
  localTrabalho: 'Filial',
  username: 'maria',
  role: 'user',
  mustChangePassword: true,
);

void main() {
  sqfliteFfiInit();
  late AppDatabase db;
  late UserRepository users;
  setUp(() {
    db = testDatabase(path: inMemoryDatabasePath);
    users = testUsers(db);
  });
  tearDown(() => db.close());

  test(
    'admin padrão é criado no banco sem armazenar a senha em texto',
    () async {
      final user = await users.authenticate(' ADMIN ', testPassword);
      expect(user, isNotNull);
      expect(user!.isAdmin, isTrue);
      expect(user.mustChangePassword, isFalse);
      expect(await users.authenticate('admin', 'errada'), isNull);
      final row = (await (await db.database).query('usuarios')).single;
      expect(row.containsKey('password'), isFalse);
      expect(row['senha_hash'], isNot(testPassword));
      expect(row['senha_hash'], startsWith('pbkdf2:1000:'));
    },
  );

  test('hash usa salts diferentes para senhas iguais', () async {
    const hasher = PasswordHasher(iterations: 1000);
    final one = await hasher.hash(testPassword);
    final two = await hasher.hash(testPassword);
    expect(one, isNot(two));
    expect(await hasher.verify(testPassword, one), isTrue);
    expect(await hasher.verify('outra', one), isFalse);
  });

  test('senha provisória bloqueia acesso até troca válida, persistida no próximo login', () async {
    final provider = await loggedAdmin(db);
    addTearDown(provider.dispose);
    await provider.saveUser(viewer, password: testPassword, creating: true);
    provider.logout();
    final user = await provider.login('maria', testPassword);
    expect(user!.mustChangePassword, isTrue);
    expect(provider.contratos, isEmpty);
    await expectLater(
      provider.saveProfile(viewer),
      throwsA(isA<RepositoryException>()),
    );
    await expectLater(
      provider.changePassword('errada', 'NovaSenha123'),
      throwsA(isA<RepositoryException>()),
    );
    await expectLater(
      provider.changePassword(testPassword, testPassword),
      throwsA(isA<RepositoryException>()),
    );
    await provider.changePassword(testPassword, 'NovaSenha123');
    expect(provider.currentUser!.mustChangePassword, isFalse);
    provider.logout();
    expect(await provider.login('maria', testPassword), isNull);
    expect(
      (await provider.login('maria', 'NovaSenha123'))!.mustChangePassword,
      isFalse,
    );
  });

  test(
    'usuário comum não grava cadastros e perfil não promove a própria conta',
    () async {
      final provider = await loggedAdmin(db);
      addTearDown(provider.dispose);
      const regular = UserModel(
        id: 'v',
        nome: 'Consulta',
        localTrabalho: 'Filial',
        username: 'consulta',
        role: 'user',
      );
      await provider.saveUser(regular, password: testPassword, creating: true);
      provider.logout();
      await expectLater(
        provider.saveUser(viewer, password: testPassword, creating: true),
        throwsA(isA<RepositoryException>()),
      );
      await provider.login('consulta', testPassword);
      await expectLater(
        provider.addContrato(
          ContratoModel(
            id: 'c',
            numeroContrato: '001',
            cliente: 'A',
            plano: 'B',
            endereco: 'C',
          ),
        ),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        provider.saveUser(viewer, password: testPassword, creating: true),
        throwsA(isA<RepositoryException>()),
      );
      final bytes = Uint8List.fromList([1, 2, 3]);
      await provider.saveProfile(
        UserModel(
          id: 'v',
          nome: 'Novo Nome',
          localTrabalho: 'Outra filial',
          username: 'consulta',
          role: 'admin',
          foto: bytes,
        ),
      );
      expect(provider.currentUser!.role, 'user');
      expect(provider.currentUser!.nome, 'Novo Nome');
      expect(provider.currentUser!.foto, orderedEquals(bytes));
      await expectLater(
        provider.saveProfile(admin),
        throwsA(isA<RepositoryException>()),
      );
      expect(provider.users, isEmpty);
      provider.logout();
      expect(provider.agendamentos, isEmpty);
    },
  );

  test(
    'não remove nem rebaixa o último admin; duplicidade é tratada',
    () async {
      final provider = await loggedAdmin(db);
      addTearDown(provider.dispose);
      await expectLater(
        provider.saveUser(
          UserModel(
            id: provider.currentUser!.id,
            nome: 'A',
            localTrabalho: 'B',
            username: 'admin',
            role: 'user',
          ),
        ),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        provider.deleteUser(provider.currentUser!.id),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        provider.saveUser(
          const UserModel(
            id: 'other',
            nome: 'A',
            localTrabalho: 'B',
            username: 'ADMIN',
            role: 'user',
          ),
          password: testPassword,
          creating: true,
        ),
        throwsA(isA<RepositoryException>()),
      );
    },
  );

  test(
    'admin redefine senha e exige nova troca; pode criar outro admin',
    () async {
      final provider = await loggedAdmin(db);
      addTearDown(provider.dispose);
      const second = UserModel(
        id: 'second',
        nome: 'Segundo Admin',
        localTrabalho: 'Central',
        username: 'second',
        role: 'admin',
      );
      await provider.saveUser(second, password: testPassword, creating: true);
      await provider.saveUser(viewer, password: testPassword, creating: true);
      await provider.saveUser(viewer, password: 'Temporaria123');
      expect(await users.authenticate('maria', testPassword), isNull);
      expect(
        (await users.authenticate(
          'maria',
          'Temporaria123',
        ))!.mustChangePassword,
        isTrue,
      );
      provider.logout();
      await provider.login('second', testPassword);
      expect(provider.isAdmin, isTrue);
      await provider.deleteUser('viewer-id');
      expect(await users.authenticate('maria', 'Temporaria123'), isNull);
    },
  );
}
