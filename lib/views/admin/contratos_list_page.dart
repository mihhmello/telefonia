import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../shared/crud_actions.dart';

class ContratosListPage extends StatelessWidget { // A página de listagem de contratos exibe todos os contratos ativos, permitindo ao usuário adicionar, editar ou excluir contratos, com validação de estado e tratamento de erros.
  const ContratosListPage({super.key});
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
                'Contratos Ativos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: provider.isSaving
                    ? null
                    : () =>
                          Navigator.pushNamed(context, '/admin/contrato-form'),
                icon: const Icon(Icons.add),
                label: const Text('Novo Contrato'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded( // A lista de contratos é exibida em um ListView, mostrando o número do contrato, cliente e plano contratado, com opções para editar ou excluir cada contrato, e tratamento de estado para desabilitar ações durante operações de salvamento.
            child: provider.contratos.isEmpty
                ? const Center(child: Text('Nenhum registro cadastrado.'))
                : ListView.builder(
                    itemCount: provider.contratos.length,
                    itemBuilder: (context, index) {
                      final item = provider.contratos[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.description,
                            color: Colors.orange,
                          ),
                          title: Text(item.numeroContrato),
                          subtitle: Text('${item.cliente} - ${item.plano}'),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/admin/contrato-detail',
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
                                        '/admin/contrato-form',
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
                                        () => provider.removeContrato(item.id),
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
