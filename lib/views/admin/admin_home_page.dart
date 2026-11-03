import 'package:flutter/material.dart';

import '../../routing/app_routes.dart';

// Compatibilidade com chamadas antigas: o acesso continua passando pela proteção.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const RouteGuard(settings: RouteSettings(name: '/admin'));
}
