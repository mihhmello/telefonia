import '../shared/person_avatar.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../shared/crud_actions.dart';

class AgendamentosListPage extends StatelessWidget {
  const AgendamentosListPage({super.key});
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
                'Visitas Agendadas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: provider.isSaving
                    ? null
                    : () => Navigator.pushNamed(
                        context,
                        '/admin/agendamento-form',
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Novo Agendamento'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provider.agendamentos.isEmpty
                ? const Center(
                    child: Text('Nenhum agendamento realizado ainda.'),
                  )
                : ListView.builder(
                    itemCount: provider.agendamentos.length,
                    itemBuilder: (context, index) {
                      final item = provider.agendamentos[index];
                      return Card(
                        child: ListTile(
                          leading: PersonAvatar(
                            photo: item.tecnico.foto,
                            legacyUrl: item.tecnico.fotoUrl,
                          ),
                          title: Text(
                            'Contrato: ${item.contrato.numeroContrato}',
                          ),
                          subtitle: Text(
                            'Técnico: ${item.tecnico.nome}\nData: ${DateFormat("dd/MM/yyyy 'às' HH:mm").format(item.dataHora)}',
                          ),
                          isThreeLine: true,
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
                                        '/admin/agendamento-form',
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
                                        () =>
                                            provider.removeAgendamento(item.id),
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
