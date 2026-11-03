import '../shared/person_avatar.dart';
import '../../utils/field_validators.dart';

import 'package:flutter/material.dart';

import '../../models/tecnico_model.dart';

class TecnicoDetailPage extends StatelessWidget {
  const TecnicoDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tecnico = ModalRoute.of(context)!.settings.arguments as TecnicoModel;

    return Scaffold(
      appBar: AppBar(title: Text(tecnico.nome), backgroundColor: Colors.orange),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Foto redonda grande do técnico
              PersonAvatar(
                photo: tecnico.foto,
                legacyUrl: tecnico.fotoUrl,
                radius: 70,
              ),
              const SizedBox(height: 24),
              Text(
                tecnico.nome,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tecnico.especialidade,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone, color: Colors.orange),
                  title: const Text('Telefone de Contato'),
                  subtitle: Text(PhoneInputFormatter.format(tecnico.telefone)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
