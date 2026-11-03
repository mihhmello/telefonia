import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../utils/field_validators.dart';
import 'shared/crud_actions.dart';
import 'shared/photo_picker_field.dart';

// O mesmo formulário atende cadastro administrativo e perfil autenticado.
class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key, this.profile = false, this.user});
  final bool profile;
  final UserModel? user;
  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

// O estado da página de formulário de usuário gerencia os campos de entrada, validação e envio dos dados do usuário, bem como o estado de carregamento.
class _UserFormPageState extends State<UserFormPage> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _workplace = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserModel? _original;
  Uint8List? _photo;
  String _role = 'user';
  bool _mustChange = true;
  bool _initialized = false;
  bool _saving = false;

// Inicializa os campos do formulário com os dados do usuário original, se disponível, e define o estado inicial do formulário.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _original = widget.profile
        ? context.read<AppProvider>().currentUser
        : widget.user;
    _name.text = _original?.nome ?? '';
    _workplace.text = _original?.localTrabalho ?? '';
    _username.text = _original?.username ?? '';
    _role = _original?.role ?? 'user';
    _mustChange = _original?.mustChangePassword ?? true;
    _photo = _original?.foto;
  }

// Descartar os controladores de texto quando o widget for removido da árvore de widgets para evitar vazamentos de memória.
  @override
  void dispose() {
    _name.dispose();
    _workplace.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

// Salva os dados do usuário, validando os campos e chamando o método de salvamento do provider, exibindo mensagens de erro se necessário e redirecionando para a tela apropriada após o salvamento bem-sucedido.
  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final user = UserModel(
      id: _original?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      nome: _name.text.trim(),
      localTrabalho: _workplace.text.trim(),
      username: _username.text.trim(),
      role: _role,
      foto: _photo,
      mustChangePassword: _mustChange,
    );
    final success = await runCrudAction(context, () {
      if (widget.profile) return provider.saveProfile(user);
      return provider.saveUser(
        user,
        creating: _original == null,
        password: _password.text.isEmpty ? null : _password.text,
      );
    });
    if (!mounted) return;
    if (success) {
      if (widget.profile) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
      } else {
        Navigator.pop(context);
      }
    } else {
      setState(() => _saving = false);
    }
  }

// Constrói a interface da página de formulário de usuário, incluindo campos de entrada para nome, local de trabalho, nome de usuário, senha e grupo, bem como um campo de seleção de foto e botões para salvar ou alterar a senha, exibindo mensagens de erro conforme necessário.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.profile
            ? 'Meu perfil'
            : _original == null
            ? 'Novo Usuário'
            : 'Editar Usuário',
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PhotoPickerField(
                  photo: _photo,
                  enabled: !_saving,
                  onChanged: (v) => setState(() => _photo = v),
                ),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: FieldValidators.requiredText,
                ),
                TextFormField(
                  controller: _workplace,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Local de trabalho',
                  ),
                  validator: FieldValidators.requiredText,
                ),
                TextFormField(
                  controller: _username,
                  enabled: !_saving,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Usuário'),
                  validator: FieldValidators.username,
                ),
                if (!widget.profile)
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(labelText: 'Grupo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Administrador'),
                      ),
                      DropdownMenuItem(
                        value: 'user',
                        child: Text('Usuário — somente consulta'),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _role = v!),
                  ),
                if (!widget.profile) ...[
                  TextFormField(
                    controller: _password,
                    enabled: !_saving,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _original == null
                          ? 'Senha'
                          : 'Nova senha provisória (opcional)',
                      helperText: _original == null
                          ? 'De 8 a 128 caracteres.'
                          : 'Em branco mantém a senha atual.',
                    ),
                    validator: (v) => _original != null && (v ?? '').isEmpty
                        ? null
                        : FieldValidators.password(v),
                  ),
                  TextFormField(
                    controller: _confirm,
                    enabled: !_saving,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar senha',
                    ),
                    validator: (v) =>
                        v != _password.text ? 'As senhas não coincidem.' : null,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Exigir alteração de senha no próximo login',
                    ),
                    subtitle: const Text(
                      'A conta só poderá acessar o sistema após trocar a senha provisória.',
                    ),
                    value: _mustChange,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _mustChange = v!),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Salvando...' : 'Salvar Usuário'),
                ),
                if (widget.profile)
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () =>
                              Navigator.pushNamed(context, '/change-password'),
                    child: const Text('Alterar minha senha'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
