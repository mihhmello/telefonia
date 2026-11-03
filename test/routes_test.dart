import 'package:telefonia_app/repositories/telefonia_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telefonia_app/models/user_model.dart';
import 'package:telefonia_app/providers/app_provider.dart';
import 'package:telefonia_app/routing/app_routes.dart';

import 'auth_helpers.dart';

void main() {
  sqfliteFfiInit();

  Future<void> open(
    WidgetTester tester,
    AppProvider provider,
    String path,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          key: UniqueKey(),
          initialRoute: path,
          onGenerateRoute: AppRoutes.generate,
          onGenerateInitialRoutes: (name) => [
            AppRoutes.generate(RouteSettings(name: name)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'URL administrativa exige login, grupo e troca de senha antes de liberar',
    (tester) async {
      final db = testDatabase(path: inMemoryDatabasePath);
      final provider = (await tester.runAsync(() => loggedAdmin(db)))!;
      await tester.runAsync(() async {
        await provider.saveUser(
          const UserModel(
            id: 'v',
            nome: 'Consulta',
            localTrabalho: 'Filial',
            username: 'consulta',
            role: 'user',
          ),
          password: testPassword,
          creating: true,
        );
        await provider.saveUser(
          const UserModel(
            id: 'temp',
            nome: 'Temporário',
            localTrabalho: 'Filial',
            username: 'temporario',
            role: 'admin',
            mustChangePassword: true,
          ),
          password: testPassword,
          creating: true,
        );
      });
      provider.logout();
      await open(tester, provider, '/admin/user-form');
      expect(find.text('Acesse sua conta'), findsOneWidget);
      expect(find.text('Novo Usuário'), findsNothing);

      await tester.runAsync(() => provider.login('consulta', testPassword));
      await open(tester, provider, '/admin/tecnico-form');
      expect(
        find.text('Acesso permitido somente a administradores.'),
        findsOneWidget,
      );
      expect(find.text('Salvar Técnico'), findsNothing);
      await open(tester, provider, '/register');
      expect(
        find.text('Acesso permitido somente a administradores.'),
        findsOneWidget,
      );
      await open(tester, provider, '/profile');
      expect(find.text('Meu perfil'), findsOneWidget);
      expect(find.text('Grupo'), findsNothing);

      await tester.runAsync(() => provider.login('temporario', testPassword));
      for (final route in ['/admin', '/admin/user-form', '/profile', '/user']) {
        await open(tester, provider, route);
        expect(
          find.text(
            'Sua senha é provisória. Defina uma nova senha para continuar.',
          ),
          findsOneWidget,
        );
        expect(find.text('Salvar Usuário'), findsNothing);
      }
      await tester.runAsync(() => provider.login('admin', testPassword));
      await open(tester, provider, '/admin/user-form');
      expect(find.text('Novo Usuário'), findsOneWidget);
      provider.logout();
      await tester.pumpAndSettle();
      expect(find.text('Acesse sua conta'), findsOneWidget);
      expect(find.text('Novo Usuário'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      await tester.runAsync(db.close);
    },
  );

  testWidgets('detalhes por URL sem argumentos não causam exceção', (
    tester,
  ) async {
    final db = testDatabase(path: inMemoryDatabasePath);
    final provider = (await tester.runAsync(() => loggedAdmin(db)))!;
    await open(tester, provider, '/admin/tecnico-detail');
    expect(find.text('Técnicos Cadastrados'), findsOneWidget);
    await open(tester, provider, '/admin/contrato-detail');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    await tester.runAsync(db.close);
  });

  testWidgets('base nova abre login e nunca oferece criação pública de conta', (
    tester,
  ) async {
    final db = testDatabase();
    final provider = AppProvider(
      repository: TelefoniaRepository(db),
      userRepository: testUsers(db),
    );
    await tester.runAsync(provider.initialize);
    for (final path in ['/', '/setup', '/register', '/admin/user-form']) {
      await open(tester, provider, path);
      expect(find.text('Acesse sua conta'), findsOneWidget);
      expect(find.text('Criar administrador inicial'), findsNothing);
      expect(find.text('Salvar Usuário'), findsNothing);
    }
    await tester.runAsync(() => provider.login('admin', '12345678'));
    expect(provider.isAdmin, isTrue);
    await open(tester, provider, '/admin/user-form');
    expect(find.text('Novo Usuário'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    await tester.runAsync(db.close);
  });
}
