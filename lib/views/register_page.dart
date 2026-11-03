import 'package:flutter/material.dart';

import '../routing/app_routes.dart';

// O widget RegisterPage é responsável por exibir a página de registro de usuários, utilizando o RouteGuard para proteger a rota e garantir que apenas usuários não autenticados possam acessá-la.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const RouteGuard(settings: RouteSettings(name: '/register'));
}
