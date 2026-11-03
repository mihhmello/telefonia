import 'package:sqflite_common/sqlite_api.dart';

import '../data/app_database.dart';
import '../models/user_model.dart';
import '../services/password_hasher.dart';
import '../utils/field_validators.dart';
import 'crud_repository.dart';

class UserRepository {
  UserRepository(this.database, {this.hasher = const PasswordHasher()});
  final AppDatabase database;
  final PasswordHasher hasher;

  Future<UserModel?> findById(String id) async {
    final rows = await (await database.database).query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.single);
  }

  Future<UserModel?> authenticate(String username, String password) async {
    final rows = await (await database.database).query(
      'usuarios',
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty ||
        !await hasher.verify(password, rows.single['senha_hash'] as String)) {
      return null;
    }
    return UserModel.fromMap(rows.single);
  }

  // Consulta o grupo no banco, em vez de confiar no grupo enviado pela tela.
  Future<UserModel> requireAccess(
    String? id, {
    bool admin = false,
    bool allowPasswordChange = false,
    DatabaseExecutor? executor,
  }) async {
    if (id == null) {
      throw const RepositoryException('Faça login para continuar.');
    }
    final db = executor ?? await database.database;
    final rows = await db.query('usuarios', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      throw const RepositoryException('Faça login para continuar.');
    }
    final user = UserModel.fromMap(rows.single);
    if (user.mustChangePassword && !allowPasswordChange) {
      throw const RepositoryException(
        'Altere sua senha provisória para continuar.',
      );
    }
    if (admin && !user.isAdmin) {
      throw const RepositoryException(
        'Acesso permitido somente a administradores.',
      );
    }
    return user;
  }

  Future<List<UserModel>> list(String actorId) async {
    await requireAccess(actorId, admin: true);
    return (await (await database.database).query(
      'usuarios',
      orderBy: 'nome COLLATE NOCASE',
    )).map(UserModel.fromMap).toList();
  }

  void _validate(UserModel user, String? password) {
    final error =
        FieldValidators.requiredText(user.nome) ??
        FieldValidators.requiredText(user.localTrabalho) ??
        FieldValidators.username(user.username) ??
        (password == null ? null : FieldValidators.password(password));
    if (error != null) throw RepositoryException(error);
    if (!['admin', 'user'].contains(user.role)) {
      throw const RepositoryException('Grupo inválido.');
    }
    if ((user.foto?.length ?? 0) > 2 * 1024 * 1024) {
      throw const RepositoryException('A foto deve ter até 2 MB.');
    }
  }

  Future<void> _translate(Future<void> Function() action) async {
    try {
      await action();
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw const RepositoryException('Este usuário já está cadastrado.');
      }
      throw const RepositoryException(
        'Não foi possível salvar o usuário. Tente novamente.',
      );
    }
  }

  Future<void> saveAsAdmin(
    String actorId,
    UserModel user, {
    String? password,
    bool creating = false,
  }) async {
    await requireAccess(actorId, admin: true);
    _validate(user, password);
    if (creating && password == null) {
      throw const RepositoryException('Informe a senha provisória.');
    }
    final hash = password == null ? null : await hasher.hash(password);
    final db = await database.database;
    await _translate(
      () => db.transaction((txn) async {
        await requireAccess(actorId, admin: true, executor: txn);
        final values = user.toMap();
        if (hash != null) values['senha_hash'] = hash;
        if (creating) {
          await txn.insert('usuarios', values);
        } else {
          final rows = await txn.query(
            'usuarios',
            where: 'id = ?',
            whereArgs: [user.id],
          );
          if (rows.isEmpty) {
            throw const RepositoryException('Usuário não encontrado.');
          }
          final old = UserModel.fromMap(rows.single);
          if (old.isAdmin && !user.isAdmin) {
            final admins = await txn.query(
              'usuarios',
              columns: ['id'],
              where: "role = 'admin'",
            );
            if (admins.length <= 1) {
              throw const RepositoryException(
                'Mantenha ao menos um administrador.',
              );
            }
          }
          // A flag só pode ser removida pelo próprio usuário ao trocar sua senha.
          if (hash == null && old.mustChangePassword) {
            values['trocar_senha'] = 1;
          }
          await txn.update(
            'usuarios',
            values,
            where: 'id = ?',
            whereArgs: [user.id],
          );
        }
      }),
    );
  }

  Future<void> updateProfile(String actorId, UserModel user) async {
    await requireAccess(actorId);
    _validate(user, null);
    if (actorId != user.id) {
      throw const RepositoryException('Edite somente seu próprio perfil.');
    }
    // Lista explícita: perfil pessoal nunca pode promover a conta ou alterar a flag.
    await _translate(() async {
      await (await database.database).update(
        'usuarios',
        {
          'nome': user.nome.trim(),
          'local_trabalho': user.localTrabalho.trim(),
          'username': user.username.trim().toLowerCase(),
          'foto': user.foto,
        },
        where: 'id = ?',
        whereArgs: [actorId],
      );
    });
  }

  Future<void> changePassword(
    String actorId,
    String currentPassword,
    String newPassword,
  ) async {
    await requireAccess(actorId, allowPasswordChange: true);
    final error = FieldValidators.password(newPassword);
    if (error != null) throw RepositoryException(error);
    final db = await database.database;
    final row = (await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [actorId],
    )).single;
    final previousHash = row['senha_hash'] as String;
    if (!await hasher.verify(currentPassword, previousHash)) {
      throw const RepositoryException('Senha atual incorreta.');
    }
    if (await hasher.verify(newPassword, previousHash)) {
      throw const RepositoryException('Escolha uma senha diferente da atual.');
    }
    final hash = await hasher.hash(newPassword);
    final updated = await db.update(
      'usuarios',
      {'senha_hash': hash, 'trocar_senha': 0},
      where: 'id = ? AND senha_hash = ?',
      whereArgs: [actorId, previousHash],
    );
    if (updated != 1) {
      throw const RepositoryException(
        'A senha foi alterada em outra operação. Entre novamente.',
      );
    }
  }

  Future<void> delete(String actorId, String id) async {
    final db = await database.database;
    await db.transaction((txn) async {
      await requireAccess(actorId, admin: true, executor: txn);
      if (actorId == id) {
        throw const RepositoryException(
          'Você não pode excluir sua própria conta.',
        );
      }
      final user = await txn.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (user.isEmpty) {
        throw const RepositoryException('Usuário não encontrado.');
      }
      if (user.single['role'] == 'admin') {
        final admins = await txn.query(
          'usuarios',
          columns: ['id'],
          where: "role = 'admin'",
        );
        if (admins.length <= 1) {
          throw const RepositoryException(
            'Mantenha ao menos um administrador.',
          );
        }
      }
      await txn.delete('usuarios', where: 'id = ?', whereArgs: [id]);
    });
  }
}
