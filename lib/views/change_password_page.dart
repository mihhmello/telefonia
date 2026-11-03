import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/field_validators.dart';
import 'shared/crud_actions.dart';

// Uma página que permite ao usuário alterar sua senha, com validação de campos e tratamento de erros, redirecionando para a tela apropriada após a alteração bem-sucedida.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, this.forced = false});
  final bool forced;
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

// O estado da página de alteração de senha, gerenciando os campos de entrada, validação e envio da nova senha, bem como o estado de carregamento.
class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _key = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

// Salva a nova senha, validando os campos e chamando o método de alteração de senha do provedor, exibindo mensagens de erro se necessário e redirecionando para a tela apropriada após a alteração bem-sucedida.
  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final success = await runCrudAction(
      context,
      () => provider.changePassword(_current.text, _password.text),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        provider.isAdmin ? '/admin' : '/user',
        (_) => false,
      );
    } else {
      setState(() => _saving = false);
    }
  }

// Constrói a interface da página de alteração de senha, incluindo campos de entrada para a senha atual, nova senha e confirmação da nova senha, bem como um botão para salvar a nova senha, exibindo mensagens de erro conforme necessário.
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.forced,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Alterar senha'),
        automaticallyImplyLeading: !widget.forced,
        actions: [
          if (widget.forced)
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      context.read<AppProvider>().logout();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (_) => false,
                      );
                    },
              child: const Text('Sair'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.forced)
                    const Text(
                      'Sua senha é provisória. Defina uma nova senha para continuar.',
                    ),
                  TextFormField(
                    controller: _current,
                    enabled: !_saving,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha atual / provisória',
                    ),
                    validator: FieldValidators.requiredText,
                  ),
                  TextFormField(
                    controller: _password,
                    enabled: !_saving,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nova senha'),
                    validator: FieldValidators.password,
                  ),
                  TextFormField(
                    controller: _confirm,
                    enabled: !_saving,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nova senha',
                    ),
                    validator: (v) =>
                        v != _password.text ? 'As senhas não coincidem.' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Salvando...' : 'Salvar nova senha'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
