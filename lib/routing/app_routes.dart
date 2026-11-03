import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../models/tecnico_model.dart';
import '../models/contrato_model.dart';
import '../models/agendamento_model.dart';
import '../providers/app_provider.dart';
import '../views/login_page.dart';
import '../views/user_form_page.dart';
import '../views/change_password_page.dart';
import '../views/admin/admin_main_page.dart';
import '../views/admin/tecnico_detail_page.dart';
import '../views/admin/tecnico_form_page.dart';
import '../views/admin/contrato_detail_page.dart';
import '../views/admin/contrato_form_page.dart';
import '../views/admin/agendamento_form_page.dart';
import '../views/user/user_home_page.dart';

class AppRoutes {
  static Route<dynamic> generate(RouteSettings settings) => MaterialPageRoute(
    settings: settings,
    builder: (_) => RouteGuard(settings: settings),
  );
}

// A checagem acontece também quando a sessão muda, e não só ao abrir a rota.
// Isso cobre URL direta, retorno pelo navegador, logout e mudança de grupo.
class RouteGuard extends StatelessWidget {
  const RouteGuard({super.key, required this.settings});
  final RouteSettings settings;

  @override
  Widget build(BuildContext context) { // O widget RouteGuard verifica o estado do usuário e redireciona para a página apropriada com base no status de autenticação, permissões e requisitos de alteração de senha, garantindo que apenas usuários autorizados acessem determinadas rotas.
    final provider = context.watch<AppProvider>();
    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = provider.currentUser;
    if (user == null) return const LoginPage();
    if (user.mustChangePassword) return const ChangePasswordPage(forced: true);

    final path = settings.name ?? '/';
    final home = user.isAdmin ? const AdminMainPage() : const UserHomePage();
    // /register deixa de ser cadastro público. Só administradores criam contas.
    if ((path.startsWith('/admin') || path == '/register') && !user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso restrito')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Acesso permitido somente a administradores.'),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/user',
                  (_) => false,
                ),
                child: const Text('Voltar à minha área'),
              ),
            ],
          ),
        ),
      );
    }
    final args = settings.arguments;
    switch (path) { // O switch case avalia a rota solicitada e retorna o widget correspondente, garantindo que apenas usuários autorizados acessem determinadas páginas e que os argumentos fornecidos sejam do tipo esperado.
      case '/':
      case '/admin':
      case '/user':
        return home;
      case '/profile':
        return const UserFormPage(profile: true);
      case '/change-password':
        return const ChangePasswordPage();
      case '/register':
      case '/admin/user-form':
        return args == null || args is UserModel
            ? UserFormPage(user: args as UserModel?)
            : home;
      case '/admin/tecnico-form':
        return args == null || args is TecnicoModel
            ? const TecnicoFormPage()
            : home;
      case '/admin/contrato-form':
        return args == null || args is ContratoModel
            ? const ContratoFormPage()
            : home;
      case '/admin/agendamento-form':
        return args == null || args is AgendamentoModel
            ? const AgendamentoFormPage()
            : home;
      // Uma URL não fornece objetos. Detalhes sem argumento voltam à listagem.
      case '/admin/tecnico-detail':
        return args is TecnicoModel ? const TecnicoDetailPage() : home;
      case '/admin/contrato-detail':
        return args is ContratoModel ? const ContratoDetailPage() : home;
      default:
        return const Scaffold(
          body: Center(child: Text('Página não encontrada.')),
        );
    }
  }
}
