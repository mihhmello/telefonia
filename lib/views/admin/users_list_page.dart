import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../shared/crud_actions.dart';
import '../shared/person_avatar.dart';

class UsersListPage extends StatelessWidget { // A página de listagem de usuários exibe todos os usuários cadastrados, permitindo ao usuário adicionar, editar ou excluir usuários, com validação de estado e tratamento de erros.
  const UsersListPage({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: provider.isSaving
                ? null
                : () => Navigator.pushNamed(context, '/admin/user-form'),
            icon: const Icon(Icons.person_add),
            label: const Text('Novo Usuário'),
          ),
        ),
        Expanded( // A lista de usuários é exibida em um ListView, mostrando o nome, nome de usuário, local de trabalho e status de cada usuário, com opções para editar ou excluir cada usuário, e tratamento de estado para desabilitar ações durante operações de salvamento.
          child: ListView.builder(
            itemCount: provider.users.length,
            itemBuilder: (context, index) {
              final user = provider.users[index];
              return Card(
                child: ListTile(
                  leading: PersonAvatar(photo: user.foto),
                  title: Text(user.nome),
                  subtitle: Text(
                    '${user.username} · ${user.localTrabalho}\n${user.isAdmin ? 'Administrador' : 'Somente consulta'}${user.mustChangePassword ? ' · Senha provisória' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar usuário',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: provider.isSaving
                            ? null
                            : () => Navigator.pushNamed(
                                context,
                                '/admin/user-form',
                                arguments: user,
                              ),
                      ),
                      IconButton(
                        tooltip: 'Excluir usuário',
                        icon: const Icon(Icons.delete_outline),
                        onPressed:
                            provider.isSaving ||
                                user.id == provider.currentUser?.id
                            ? null
                            : () => confirmDelete(
                                context,
                                () => provider.deleteUser(user.id),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
