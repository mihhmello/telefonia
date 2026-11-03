import 'package:sqflite_common/sqlite_api.dart';

import '../data/app_database.dart';

class RepositoryException implements Exception { // Exceção personalizada para erros de repositório, encapsulando uma mensagem de erro legível.
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

// Retorna todos os registros da tabela, ordenados pelo campo especificado, mapeando cada registro para o tipo T usando a função fromMap.
  Future<List<T>> findAll() async {
    final db = await database.database;
    return (await db.query(table, orderBy: orderBy)).map(fromMap).toList();
  }

// Retorna um registro específico da tabela pelo ID, mapeando o registro para o tipo T usando a função fromMap, ou null se o registro não for encontrado.
  Future<void> create(T item) => _write(() async {
    await (await database.database).insert(table, toMap(item));
  });

// Atualiza um registro existente no banco de dados, lançando uma exceção se o registro não for encontrado.
  Future<void> update(T item) => _write(() async { // Atualiza um registro existente no banco de dados, lançando uma exceção se o registro não for encontrado.
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

// Exclui um registro específico da tabela pelo ID, lançando uma exceção se o registro não for encontrado.
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

// Executa uma ação de escrita no banco de dados, capturando exceções específicas do SQLite e lançando exceções de repositório com mensagens legíveis para o usuário.
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
