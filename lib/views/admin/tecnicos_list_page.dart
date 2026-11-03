import '../shared/person_avatar.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../shared/crud_actions.dart';

class TecnicosListPage extends StatelessWidget { // A página de listagem de técnicos exibe todos os técnicos cadastrados, permitindo ao usuário adicionar, editar ou excluir técnicos, com validação de estado e tratamento de erros.
  const TecnicosListPage({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Técnicos Cadastrados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: provider.isSaving
                    ? null
                    : () => Navigator.pushNamed(context, '/admin/tecnico-form'),
                icon: const Icon(Icons.add),
                label: const Text('Novo Técnico'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded( // A lista de técnicos é exibida em um ListView, mostrando o nome e especialidade de cada técnico, com opções para editar ou excluir cada técnico, e tratamento de estado para desabilitar ações durante operações de salvamento.
            child: provider.tecnicos.isEmpty
                ? const Center(child: Text('Nenhum registro cadastrado.'))
                : ListView.builder(
                    itemCount: provider.tecnicos.length,
                    itemBuilder: (context, index) {
                      final item = provider.tecnicos[index];
                      return Card(
                        child: ListTile(
                          leading: PersonAvatar(
                            photo: item.foto,
                            legacyUrl: item.fotoUrl,
                          ),
                          title: Text(item.nome),
                          subtitle: Text(item.especialidade),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/admin/tecnico-detail',
                            arguments: item,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: provider.isSaving
                                    ? null
                                    : () => Navigator.pushNamed(
                                        context,
                                        '/admin/tecnico-form',
                                        arguments: item,
                                      ),
                              ),
                              IconButton(
                                tooltip: 'Excluir',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: provider.isSaving
                                    ? null
                                    : () => confirmDelete(
                                        context,
                                        () => provider.removeTecnico(item.id),
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
      ),
    );
  }
}
