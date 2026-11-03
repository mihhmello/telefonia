import 'dart:typed_data';

import '../../utils/field_validators.dart';
import '../shared/photo_picker_field.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tecnico_model.dart';
import '../../providers/app_provider.dart';
import '../shared/crud_actions.dart';

class TecnicoFormPage extends StatefulWidget {
  const TecnicoFormPage({super.key});
  @override
  State<TecnicoFormPage> createState() => _TecnicoFormPageState();
}

class _TecnicoFormPageState extends State<TecnicoFormPage> {
  final _formKey = GlobalKey<FormState>();
  TecnicoModel? _original;
  Uint8List? _photo;
  bool _initialized = false;
  bool _saving = false;
  final _nome = TextEditingController();
  final _especialidade = TextEditingController();
  final _telefone = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _original = ModalRoute.of(context)!.settings.arguments as TecnicoModel?;
    _nome.text = _original?.nome ?? '';
    _especialidade.text = _original?.especialidade ?? '';
    _telefone.text = PhoneInputFormatter.format(_original?.telefone ?? '');
    _photo = _original?.foto;
  }

  @override
  void dispose() {
    _nome.dispose();
    _especialidade.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final value = TecnicoModel(
      id: _original?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      nome: _nome.text.trim(),
      especialidade: _especialidade.text.trim(),
      telefone: FieldValidators.digits(_telefone.text),
      foto: _photo,
      fotoUrl: _original?.fotoUrl ?? '',
    );
    final success = await runCrudAction(
      context,
      () => _original == null
          ? provider.addTecnico(value)
          : provider.updateTecnico(value),
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
      title: Text(_original == null ? 'Cadastrar Técnico' : 'Editar Técnico'),
      backgroundColor: Colors.orange,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            PhotoPickerField(
              photo: _photo,
              legacyUrl: _original?.fotoUrl ?? '',
              enabled: !_saving,
              onChanged: (v) => setState(() => _photo = v),
            ),
            TextFormField(
              controller: _nome,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Nome do Técnico'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            TextFormField(
              controller: _especialidade,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Especialidade'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            TextFormField(
              controller: _telefone,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Telefone (DDD)'),
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              validator: FieldValidators.phone,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Salvando...' : 'Salvar Técnico'),
            ),
          ],
        ),
      ),
    ),
  );
}
