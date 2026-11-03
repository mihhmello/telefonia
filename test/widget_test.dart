import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telefonia_app/main.dart';

import 'auth_helpers.dart';

import 'package:telefonia_app/repositories/telefonia_repository.dart';

void main() {
  sqfliteFfiInit();
  testWidgets('login e cadastro de técnico persistido pelo formulário', (
    tester,
  ) async {
    final database = testDatabase(path: inMemoryDatabasePath);
    final provider = (await tester.runAsync(() => loggedAdmin(database)))!;
    provider.logout();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: provider, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), testPassword);
    await tester.ensureVisible(find.text('Entrar'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Entrar'));
      for (var i = 0; i < 200 && provider.currentUser == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Nenhum registro cadastrado.'), findsOneWidget);
    await tester.tap(find.text('Novo Técnico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar Técnico'));
    await tester.pumpAndSettle();
    expect(find.text('Campo obrigatório'), findsNWidgets(2));
    expect(
      find.text('Informe DDD e telefone com 10 ou 11 dígitos.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), 'Telefonia IP');
    await tester.enterText(find.byType(TextFormField).at(2), '42999999999');
    await tester.runAsync(() async {
      await tester.tap(find.text('Salvar Técnico'));
      // Aguarda autorização e gravação FFI fora do relógio virtual do teste.
      for (var i = 0; i < 500 && provider.tecnicos.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(
      (await tester.runAsync(() => TelefoniaRepository(database).load()))!
          .tecnicos
          .single
          .nome,
      'Ana',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    await tester.runAsync(database.close);
  });
}
