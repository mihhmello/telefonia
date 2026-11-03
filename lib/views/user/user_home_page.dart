import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';
import '../../models/agendamento_model.dart';
import '../shared/account_menu.dart';
import '../shared/person_avatar.dart';
import '../../utils/field_validators.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  // Exibe o Modal com as informações do técnico e contrato ao clicar
  void _mostrarDetalhesAgendamento(
    BuildContext context,
    AgendamentoModel agendamento,
  ) {
    final dataFormatada = DateFormat(
      "dd/MM/yyyy 'às' HH:mm",
      'pt_BR',
    ).format(agendamento.dataHora);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Foto redonda grande do técnico responsável
              PersonAvatar(
                photo: agendamento.tecnico.foto,
                legacyUrl: agendamento.tecnico.fotoUrl,
              ),
              const SizedBox(height: 12),
              Text(
                agendamento.tecnico.nome,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                agendamento.tecnico.especialidade,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Divider(height: 30),

              // Dados do Contrato e Visita
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.assignment, color: Colors.orange),
                title: Text('Contrato: ${agendamento.contrato.numeroContrato}'),
                subtitle: Text(
                  'Cliente: ${agendamento.contrato.cliente}\nPlano: ${agendamento.contrato.plano}',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event, color: Colors.orange),
                title: const Text('Data e Horário da Visita'),
                subtitle: Text(
                  dataFormatada,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone, color: Colors.orange),
                title: const Text('Contato do Técnico'),
                subtitle: Text(
                  PhoneInputFormatter.format(agendamento.tecnico.telefone),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamados e Atendimentos'),
        backgroundColor: Colors.orange,
        actions: const [AccountMenu()],
      ),
      body: provider.agendamentos.isEmpty
          ? const Center(
              child: Text(
                'Nenhum atendimento agendado no momento.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seus Agendamentos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.agendamentos.length,
                      itemBuilder: (context, index) {
                        final agendamento = provider.agendamentos[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: PersonAvatar(
                              photo: agendamento.tecnico.foto,
                              legacyUrl: agendamento.tecnico.fotoUrl,
                            ),
                            title: Text(
                              'Contrato: ${agendamento.contrato.numeroContrato}',
                            ),
                            subtitle: Text(
                              'Técnico: ${agendamento.tecnico.nome}\nClique para ver mais detalhes',
                            ),
                            trailing: const Icon(
                              Icons.touch_app,
                              color: Colors.orange,
                            ),
                            isThreeLine: true,
                            onTap: () => _mostrarDetalhesAgendamento(
                              context,
                              agendamento,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
