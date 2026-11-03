import 'package:flutter/material.dart';

import '../routing/app_routes.dart';

// Compatibilidade com chamadas antigas: o acesso continua passando pela proteção.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const RouteGuard(settings: RouteSettings(name: '/register'));
}
