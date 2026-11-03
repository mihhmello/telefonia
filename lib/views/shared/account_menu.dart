import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import 'person_avatar.dart';

class AccountMenu extends StatelessWidget { // Widget que exibe o menu de conta do usuário, incluindo opções para acessar o perfil e sair da sessão.
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
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);// Redireciona para a página de login após o logout, removendo todas as rotas anteriores da pilha de navegação.
        } else {
          Navigator.pushNamed(context, '/profile');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text('${user?.nome ?? ''}\n${user?.username ?? ''}'),// Exibe o nome e o nome de usuário do usuário atual no menu suspenso, desabilitando a seleção desse item.
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
