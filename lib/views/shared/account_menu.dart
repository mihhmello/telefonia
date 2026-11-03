import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import 'person_avatar.dart';

class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    return PopupMenuButton<String>(
      tooltip: 'Meu perfil e sessão',
      onSelected: (value) {
        if (value == 'logout') {
          provider.logout();
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        } else {
          Navigator.pushNamed(context, '/profile');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text('${user?.nome ?? ''}\n${user?.username ?? ''}'),
        ),
        const PopupMenuItem(value: 'profile', child: Text('Meu perfil')),
        const PopupMenuItem(value: 'logout', child: Text('Sair')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: PersonAvatar(photo: user?.foto, radius: 20),
      ),
    );
  }
}
