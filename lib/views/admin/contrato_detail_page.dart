import 'package:flutter/material.dart';

import '../../models/contrato_model.dart';

class ContratoDetailPage extends StatelessWidget {
  const ContratoDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final contrato =
        ModalRoute.of(context)!.settings.arguments as ContratoModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(contrato.numeroContrato),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cliente: ${contrato.cliente}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Text('Plano Contratado: ${contrato.plano}'),
                const SizedBox(height: 8),
                Text('Endereço de Instalação: ${contrato.endereco}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
