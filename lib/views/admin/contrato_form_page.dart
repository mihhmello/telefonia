import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/contrato_model.dart';
import '../../providers/app_provider.dart';
import '../shared/crud_actions.dart';

class ContratoFormPage extends StatefulWidget {
  const ContratoFormPage({super.key});
  @override
  State<ContratoFormPage> createState() => _ContratoFormPageState();
}

class _ContratoFormPageState extends State<ContratoFormPage> {
  final _formKey = GlobalKey<FormState>();
  ContratoModel? _original;
  bool _initialized = false;
  bool _saving = false;
  final _numeroContrato = TextEditingController();
  final _cliente = TextEditingController();
  final _plano = TextEditingController();
  final _endereco = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _original = ModalRoute.of(context)!.settings.arguments as ContratoModel?;
    _numeroContrato.text = _original?.numeroContrato ?? '';
    _cliente.text = _original?.cliente ?? '';
    _plano.text = _original?.plano ?? '';
    _endereco.text = _original?.endereco ?? '';
  }

  @override
  void dispose() {
    _numeroContrato.dispose();
    _cliente.dispose();
    _plano.dispose();
    _endereco.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final value = ContratoModel(
      id: _original?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      numeroContrato: _numeroContrato.text.trim(),
      cliente: _cliente.text.trim(),
      plano: _plano.text.trim(),
      endereco: _endereco.text.trim(),
    );
    final success = await runCrudAction(
      context,
      () => _original == null
          ? provider.addContrato(value)
          : provider.updateContrato(value),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_original == null ? 'Cadastrar Contrato' : 'Editar Contrato'),
      backgroundColor: Colors.orange,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _numeroContrato,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Número do Contrato',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            TextFormField(
              controller: _cliente,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Nome do Cliente'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            TextFormField(
              controller: _plano,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Plano Telefônico'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            TextFormField(
              controller: _endereco,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Endereço'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Salvando...' : 'Salvar Contrato'),
            ),
          ],
        ),
      ),
    ),
  );
}
