import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/agendamento_model.dart';
import '../../providers/app_provider.dart';
import '../shared/crud_actions.dart';

class AgendamentoFormPage extends StatefulWidget {
  const AgendamentoFormPage({super.key});
  @override
  State<AgendamentoFormPage> createState() => _AgendamentoFormPageState();
}

class _AgendamentoFormPageState extends State<AgendamentoFormPage> {
  final _formKey = GlobalKey<FormState>();
  AgendamentoModel? _original;
  String? _tecnicoId;
  String? _contratoId;
  DateTime _dataHora = DateTime.now().add(const Duration(hours: 1));
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _original = ModalRoute.of(context)!.settings.arguments as AgendamentoModel?;
    _tecnicoId = _original?.tecnico.id;
    _contratoId = _original?.contrato.id;
    _dataHora =
        _original?.dataHora ??
        DateTime(
          _dataHora.year,
          _dataHora.month,
          _dataHora.day,
          _dataHora.hour,
          _dataHora.minute,
        );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) {
      setState(
        () => _dataHora = DateTime(
          value.year,
          value.month,
          value.day,
          _dataHora.hour,
          _dataHora.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );
    if (value != null && mounted) {
      setState(
        () => _dataHora = DateTime(
          _dataHora.year,
          _dataHora.month,
          _dataHora.day,
          value.hour,
          value.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if ((_original == null || _original!.dataHora != _dataHora) &&
        !_dataHora.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma data e horário futuros.')),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final value = AgendamentoModel(
      id: _original?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      tecnico: provider.tecnicos.firstWhere((t) => t.id == _tecnicoId),
      contrato: provider.contratos.firstWhere((c) => c.id == _contratoId),
      dataHora: _dataHora,
    );
    final success = await runCrudAction(
      context,
      () => _original == null
          ? provider.addAgendamento(value)
          : provider.updateAgendamento(value),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final canSchedule =
        provider.tecnicos.isNotEmpty && provider.contratos.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _original == null ? 'Agendar Visita Técnica' : 'Editar Agendamento',
        ),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!canSchedule)
                const Text(
                  'Cadastre ao menos um técnico e um contrato antes de agendar.',
                ),
              DropdownButtonFormField<String>(
                initialValue: _tecnicoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Técnico'),
                items: provider.tecnicos
                    .map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.nome)),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _tecnicoId = v),
                validator: (v) => v == null ? 'Selecione o técnico' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _contratoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Contrato'),
                items: provider.contratos
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.numeroContrato} - ${c.cliente}'),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _contratoId = v),
                validator: (v) => v == null ? 'Selecione o contrato' : null,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('dd/MM/yyyy').format(_dataHora)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(DateFormat('HH:mm').format(_dataHora)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving || !canSchedule ? null : _save,
                child: Text(_saving ? 'Salvando...' : 'Salvar Agendamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
