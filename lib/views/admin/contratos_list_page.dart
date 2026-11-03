import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../shared/crud_actions.dart';

class ContratosListPage extends StatelessWidget {
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
          Expanded(
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
