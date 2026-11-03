import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telefonia_app/data/app_database.dart';
import 'package:telefonia_app/models/tecnico_model.dart';
import 'package:telefonia_app/models/contrato_model.dart';
import 'package:telefonia_app/models/agendamento_model.dart';

import 'auth_helpers.dart';

import 'package:telefonia_app/repositories/crud_repository.dart';
import 'package:telefonia_app/repositories/telefonia_repository.dart';

TecnicoModel tecnico({String id = 't1', String nome = 'Ana'}) => TecnicoModel(
  id: id,
  nome: nome,
  especialidade: 'Telefonia IP',
  telefone: '42999999999',
  fotoUrl: '',
);
ContratoModel contrato({
  String id = 'c1',
  String numero = 'CT-001',
  String cliente = 'Cliente',
}) => ContratoModel(
  id: id,
  numeroContrato: numero,
  cliente: cliente,
  plano: 'Fibra',
  endereco: 'Rua A, 10',
);
AgendamentoModel visita({
  String id = 'a1',
  TecnicoModel? t,
  ContratoModel? c,
  DateTime? data,
}) => AgendamentoModel(
  id: id,
  tecnico: t ?? tecnico(),
  contrato: c ?? contrato(),
  dataHora: data ?? DateTime(2027, 1, 10, 14),
);

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late TelefoniaRepository repository;
  setUp(() {
    database = testDatabase(path: inMemoryDatabasePath);
    repository = TelefoniaRepository(database);
  });
  tearDown(() => database.close());

  Future<void> populate() async {
    await repository.tecnicos.create(tecnico());
    await repository.contratos.create(contrato());
    await repository.agendamentos.create(visita());
  }

  test('CRUD completo e vínculos refletem edições dos cadastros', () async {
    expect((await repository.load()).tecnicos, isEmpty);
    await populate();
    await repository.tecnicos.update(tecnico(nome: 'Ana Souza'));
    await repository.contratos.update(contrato(cliente: 'Empresa'));
    await repository.agendamentos.update(
      visita(data: DateTime(2027, 2, 1, 10)),
    );
    final snapshot = await repository.load();
    expect(snapshot.tecnicos.single.nome, 'Ana Souza');
    expect(snapshot.contratos.single.cliente, 'Empresa');
    expect(snapshot.agendamentos.single.tecnico.nome, 'Ana Souza');
    expect(snapshot.agendamentos.single.contrato.cliente, 'Empresa');
    expect(snapshot.agendamentos.single.dataHora, DateTime(2027, 2, 1, 10));
    await repository.agendamentos.delete('a1');
    await repository.tecnicos.delete('t1');
    await repository.contratos.delete('c1');
    final empty = await repository.load();
    expect(empty.tecnicos, isEmpty);
    expect(empty.contratos, isEmpty);
    expect(empty.agendamentos, isEmpty);
  });

  test('impede exclusão de técnico/contrato referenciados', () async {
    await populate();
    await expectLater(
      repository.tecnicos.delete('t1'),
      throwsA(isA<RepositoryException>()),
    );
    await expectLater(
      repository.contratos.delete('c1'),
      throwsA(isA<RepositoryException>()),
    );
    expect((await repository.load()).agendamentos, hasLength(1));
  });

  test(
    'rejeita contratos duplicados inclusive com maiúsculas diferentes',
    () async {
      await repository.contratos.create(contrato());
      await expectLater(
        repository.contratos.create(contrato(id: 'c2', numero: 'ct-001')),
        throwsA(isA<RepositoryException>()),
      );
    },
  );

  test(
    'rejeita horário duplicado para o mesmo técnico e vínculos inexistentes',
    () async {
      await populate();
      await expectLater(
        repository.agendamentos.create(visita(id: 'a2')),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        repository.agendamentos.create(
          visita(
            id: 'a3',
            t: tecnico(id: 'inexistente'),
          ),
        ),
        throwsA(isA<RepositoryException>()),
      );
      await repository.tecnicos.create(tecnico(id: 't2'));
      await repository.agendamentos.create(
        visita(
          id: 'a4',
          t: tecnico(id: 't2'),
        ),
      );
      expect((await repository.load()).agendamentos, hasLength(2));
    },
  );

  test('atualizar registro inexistente não cria novo cadastro', () async {
    await expectLater(
      repository.tecnicos.update(tecnico()),
      throwsA(isA<RepositoryException>()),
    );
    expect((await repository.load()).tecnicos, isEmpty);
  });

  test('banco mantém dados após fechar e reabrir a conexão', () async {
    final directory = await Directory.systemTemp.createTemp('telefonia_test_');
    final path = p.join(directory.path, 'telefonia.db');
    final first = testDatabase(path: path);
    final second = testDatabase(path: path);
    try {
      final repo = TelefoniaRepository(first);
      await repo.tecnicos.create(tecnico());
      await repo.contratos.create(contrato());
      await repo.agendamentos.create(visita());
      await first.close();
      final snapshot = await TelefoniaRepository(second).load();
      expect(snapshot.tecnicos.single.nome, 'Ana');
      expect(snapshot.contratos.single.numeroContrato, 'CT-001');
      expect(snapshot.agendamentos.single.tecnico.id, 't1');
    } finally {
      await first.close();
      await second.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'Provider só altera listas após sucesso e libera estado após erro',
    () async {
      final provider = await loggedAdmin(database);
      addTearDown(provider.dispose);
      await provider.initialize();
      expect(provider.loadError, isNull);
      expect(provider.isLoading, isFalse);
      await provider.addContrato(contrato());
      await expectLater(
        provider.addContrato(contrato(id: 'c2')),
        throwsA(isA<RepositoryException>()),
      );
      expect(provider.contratos, hasLength(1));
      expect(provider.isSaving, isFalse);
      expect(() => provider.contratos.clear(), throwsUnsupportedError);
    },
  );
}
