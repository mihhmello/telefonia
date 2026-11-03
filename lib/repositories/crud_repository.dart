import 'package:sqflite_common/sqlite_api.dart';

import '../data/app_database.dart';

class RepositoryException implements Exception {
  const RepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// SQL parametrizado e operações comuns, reutilizáveis pelos cadastros.
class CrudRepository<T> {
  CrudRepository(
    this.database,
    this.table,
    this.fromMap,
    this.toMap, {
    required this.orderBy,
  });
  final AppDatabase database;
  final String table;
  final String orderBy;
  final T Function(Map<String, Object?>) fromMap;
  final Map<String, Object?> Function(T) toMap;

  Future<List<T>> findAll() async {
    final db = await database.database;
    return (await db.query(table, orderBy: orderBy)).map(fromMap).toList();
  }

  Future<void> create(T item) => _write(() async {
    await (await database.database).insert(table, toMap(item));
  });

  Future<void> update(T item) => _write(() async {
    final values = toMap(item);
    final count = await (await database.database).update(
      table,
      values,
      where: 'id = ?',
      whereArgs: [values['id']],
    );
    if (count != 1) {
      throw const RepositoryException(
        'Registro não encontrado. Atualize a lista.',
      );
    }
  });

  Future<void> delete(String id) => _write(() async {
    final count = await (await database.database).delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) {
      throw const RepositoryException(
        'Registro não encontrado. Atualize a lista.',
      );
    }
  });

  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw RepositoryException(
          table == 'contratos'
              ? 'Já existe um contrato com esse número.'
              : 'O técnico já possui um agendamento nesse horário.',
        );
      }
      if (e.toString().contains('FOREIGN KEY')) {
        throw const RepositoryException(
          'Não foi possível concluir: verifique os vínculos com agendamentos. Remova os agendamentos antes de excluir um técnico ou contrato.',
        );
      }
      if (e.toString().contains('CHECK constraint')) {
        throw const RepositoryException(
          'Preencha todos os campos obrigatórios.',
        );
      }
      throw const RepositoryException(
        'Não foi possível salvar no banco de dados. Tente novamente.',
      );
    }
  }
}
