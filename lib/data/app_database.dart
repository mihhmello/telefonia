import '../services/password_hasher.dart';

import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';

import 'database_factory.dart';

/// Gerencia conexão e versão do esquema. A factory e o caminho são
/// injetáveis para testar o SQL real sem acessar o banco do usuário.
class AppDatabase {
  AppDatabase({
    DatabaseFactory? factory,
    this.path,
    this.initialAdminHasher = const PasswordHasher(),
  }) : _factory = factory ?? createDatabaseFactory();

  final PasswordHasher initialAdminHasher;
  final DatabaseFactory _factory;
  final String? path;
  Database? _database;
  Future<Database>? _opening;

  Future<Database> get database async {
    if (_database != null) return _database!;
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final databasePath =
          path ?? p.join(await _factory.getDatabasesPath(), 'telefonia.db');
      _database = await _factory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          // Migração preserva as tabelas e registros da versão anterior.
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await _createUsers(db);
              await db.execute('ALTER TABLE tecnicos ADD COLUMN foto BLOB');
            }
            if (oldVersion < 3) await _seedAdmin(db);
          },
          onCreate: (db, version) async {
            await _createUsers(db);
            await db.execute('''CREATE TABLE tecnicos (
              id TEXT PRIMARY KEY NOT NULL,
              nome TEXT NOT NULL CHECK(length(trim(nome)) > 0),
              especialidade TEXT NOT NULL CHECK(length(trim(especialidade)) > 0),
              telefone TEXT NOT NULL CHECK(length(trim(telefone)) > 0),
              foto_url TEXT NOT NULL DEFAULT '',
              foto BLOB
            )''');
            await db.execute('''CREATE TABLE contratos (
              id TEXT PRIMARY KEY NOT NULL,
              numero_contrato TEXT NOT NULL COLLATE NOCASE UNIQUE
                CHECK(length(trim(numero_contrato)) > 0),
              cliente TEXT NOT NULL CHECK(length(trim(cliente)) > 0),
              plano TEXT NOT NULL CHECK(length(trim(plano)) > 0),
              endereco TEXT NOT NULL CHECK(length(trim(endereco)) > 0)
            )''');
            await db.execute('''CREATE TABLE agendamentos (
              id TEXT PRIMARY KEY NOT NULL,
              tecnico_id TEXT NOT NULL REFERENCES tecnicos(id) ON DELETE RESTRICT,
              contrato_id TEXT NOT NULL REFERENCES contratos(id) ON DELETE RESTRICT,
              data_hora INTEGER NOT NULL,
              UNIQUE(tecnico_id, data_hora)
            )''');
            await db.execute(
              'CREATE INDEX idx_agendamento_contrato ON agendamentos(contrato_id)',
            );
            await _seedAdmin(db);
          },
        ),
      );
      return _database!;
    } finally {
      _opening = null;
    }
  }

  // Executado somente ao criar a base ou migrar para a versão 3.
  // Nunca redefina a senha no onOpen: isso apagaria as mudanças feitas pelo admin.
  Future<void> _seedAdmin(DatabaseExecutor db) async {
    final hash = await initialAdminHasher.hash('12345678');
    final existing = await db.query(
      'usuarios',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: ['admin'],
    );
    if (existing.isEmpty) {
      await db.insert('usuarios', {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'nome': 'Administrador',
        'local_trabalho': 'Administração',
        'username': 'admin',
        'senha_hash': hash,
        'role': 'admin',
        'trocar_senha': 0,
      });
    } else {
      // Preserva ID, nome, local e foto da conta que já existia.
      await db.update(
        'usuarios',
        {'senha_hash': hash, 'role': 'admin', 'trocar_senha': 0},
        where: 'id = ?',
        whereArgs: [existing.single['id']],
      );
    }
  }

  static Future<void> _createUsers(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE usuarios (
      id TEXT PRIMARY KEY NOT NULL,
      nome TEXT NOT NULL CHECK(length(trim(nome)) > 0),
      local_trabalho TEXT NOT NULL CHECK(length(trim(local_trabalho)) > 0),
      username TEXT NOT NULL COLLATE NOCASE UNIQUE CHECK(length(trim(username)) >= 3),
      senha_hash TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN ('admin', 'user')),
      trocar_senha INTEGER NOT NULL DEFAULT 0 CHECK(trocar_senha IN (0, 1)),
      foto BLOB
    )''');
  }

  Future<void> close() async {
    if (_opening != null) await _opening;
    await _database?.close();
    _database = null;
  }
}
