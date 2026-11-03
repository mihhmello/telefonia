import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telefonia_app/models/tecnico_model.dart';
import 'package:telefonia_app/models/user_model.dart';
import 'package:telefonia_app/repositories/telefonia_repository.dart';

import 'auth_helpers.dart';

void main() {
  sqfliteFfiInit();
  test(
    'migração v1 para v3 preserva técnico, contrato e visita; fotos persistem',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'telefonia_migration_',
      );
      final path = p.join(directory.path, 'test.db');
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              "CREATE TABLE tecnicos (id TEXT PRIMARY KEY, nome TEXT, especialidade TEXT, telefone TEXT, foto_url TEXT)",
            );
            await db.execute(
              "CREATE TABLE contratos (id TEXT PRIMARY KEY, numero_contrato TEXT, cliente TEXT, plano TEXT, endereco TEXT)",
            );
            await db.execute(
              "CREATE TABLE agendamentos (id TEXT PRIMARY KEY, tecnico_id TEXT REFERENCES tecnicos(id), contrato_id TEXT REFERENCES contratos(id), data_hora INTEGER)",
            );
            await db.insert('tecnicos', {
              'id': 't',
              'nome': 'Antigo',
              'especialidade': 'IP',
              'telefone': '42999991234',
              'foto_url': '',
            });
            await db.insert('contratos', {
              'id': 'c',
              'numero_contrato': 'CT-01',
              'cliente': 'Cliente',
              'plano': 'Plano',
              'endereco': 'Rua',
            });
            await db.insert('agendamentos', {
              'id': 'a',
              'tecnico_id': 't',
              'contrato_id': 'c',
              'data_hora': DateTime(2027).millisecondsSinceEpoch,
            });
          },
        ),
      );
      await old.close();
      final upgraded = testDatabase(path: path);
      final reopened = testDatabase(path: path);
      try {
        final repo = TelefoniaRepository(upgraded);
        final snapshot = await repo.load();
        expect(snapshot.agendamentos.single.tecnico.nome, 'Antigo');
        expect(snapshot.agendamentos.single.contrato.numeroContrato, 'CT-01');
        final photo = Uint8List.fromList([1, 3, 5, 7]);
        await repo.tecnicos.update(
          TecnicoModel(
            id: 't',
            nome: 'Antigo',
            especialidade: 'IP',
            telefone: '42999991234',
            fotoUrl: '',
            foto: photo,
          ),
        );
        final users = testUsers(upgraded);
        final currentAdmin = (await users.authenticate('admin', testPassword))!;
        await users.saveAsAdmin(
          currentAdmin.id,
          UserModel(
            id: currentAdmin.id,
            nome: 'Admin',
            localTrabalho: 'Sede',
            username: 'admin',
            role: 'admin',
            foto: photo,
          ),
        );
        await upgraded.close();
        expect(
          (await TelefoniaRepository(reopened).load()).tecnicos.single.foto,
          orderedEquals(photo),
        );
        expect(
          (await testUsers(reopened).authenticate('admin', testPassword))!.foto,
          orderedEquals(photo),
        );
      } finally {
        await upgraded.close();
        await reopened.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('migração v2 configura admin uma vez e preserva a senha alterada ao reabrir', () async {
    final directory = await Directory.systemTemp.createTemp(
      'telefonia_admin_migration_',
    );
    final path = p.join(directory.path, 'test.db');
    final previous = testDatabase(path: path);
    final upgraded = testDatabase(path: path);
    final reopened = testDatabase(path: path);
    try {
      final users = testUsers(previous);
      final original = (await users.authenticate('admin', testPassword))!;
      final photo = Uint8List.fromList([1, 2, 3]);
      await users.saveAsAdmin(
        original.id,
        UserModel(
          id: original.id,
          nome: 'Nome existente',
          localTrabalho: 'Local existente',
          username: 'admin',
          role: 'admin',
          foto: photo,
        ),
        password: 'SenhaAntiga123',
      );
      await users.saveAsAdmin(
        original.id,
        const UserModel(
          id: 'other',
          nome: 'Outro usuário',
          localTrabalho: 'Filial',
          username: 'consulta',
          role: 'user',
        ),
        password: 'OutraSenha123',
        creating: true,
      );
      // A tabela da versão 2 tem os mesmos campos; simula uma base anterior à nova carga inicial.
      await (await previous.database).execute('PRAGMA user_version = 2');
      await previous.close();

      final migrated = testUsers(upgraded);
      final admin = (await migrated.authenticate('admin', '12345678'))!;
      expect(admin.id, original.id);
      expect(admin.nome, 'Nome existente');
      expect(admin.foto, orderedEquals(photo));
      expect(
        (await migrated.authenticate('consulta', 'OutraSenha123'))!.id,
        'other',
      );
      await migrated.changePassword(admin.id, '12345678', 'SenhaDefinitiva123');
      await upgraded.close();
      final afterRestart = testUsers(reopened);
      expect(await afterRestart.authenticate('admin', '12345678'), isNull);
      expect(
        await afterRestart.authenticate('admin', 'SenhaDefinitiva123'),
        isNotNull,
      );
      expect((await (await reopened.database).query('usuarios')).length, 2);
    } finally {
      await previous.close();
      await upgraded.close();
      await reopened.close();
      await directory.delete(recursive: true);
    }
  });
}
