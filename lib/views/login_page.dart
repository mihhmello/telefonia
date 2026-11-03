import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'shared/crud_actions.dart';

// A página de login permite que o usuário insira seu nome de usuário e senha para acessar a aplicação, com validação de campos e tratamento de erros.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

// O estado da página de login gerencia os campos de entrada, validação e envio das credenciais do usuário, bem como o estado de carregamento.
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

// Tenta efetuar o login do usuário, validando os campos e chamando o método de login do provedor, exibindo mensagens de erro se necessário e redirecionando para a tela apropriada após o login bem-sucedido.
  Future<void> _login() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    final success = await runCrudAction(context, () async {
      final user = await provider.login(_username.text, _password.text);
      if (user == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário ou senha incorretos!')),
        );
      }
    });
    if (!mounted) return;
    if (success && provider.currentUser != null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        provider.currentUser!.mustChangePassword
            ? '/change-password'
            : provider.isAdmin
            ? '/admin'
            : '/user',
        (_) => false,
      );
    } else {
      setState(() => _loading = false);
    }
  }

  // Os links mantêm o visual anterior, contas e senhas são administradas internamente.
  void _accountHelp({bool password = false}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(password ? 'Redefinir senha' : 'Solicitar cadastro'),
        content: Text(
          password
              ? 'Procure o administrador para receber uma senha provisória.'
              : 'Procure o administrador para cadastrar sua conta e definir seu grupo de acesso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

// Constrói a interface da página de login, incluindo campos de entrada para o nome de usuário e senha, um botão para efetuar o login e links para solicitar cadastro ou redefinir a senha, exibindo mensagens de erro conforme necessário.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Acesse sua conta',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por favor, faça login para continuar',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Campo Usuário
                const Text(
                  'Usuário / E-mail',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _username,
                  enabled: !_loading,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Digite seu usuário',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.orange,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, informe seu usuário';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Senha
                const Text(
                  'Senha',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _password,
                  enabled: !_loading,
                  onFieldSubmitted: (_) => _login(),
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Digite sua senha',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.orange,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe sua senha';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Esqueceu a senha
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _accountHelp(password: true),
                    child: const Text(
                      'Esqueceu a senha?',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Entrar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _loading ? null : _login,
                    child: Text(
                      _loading ? 'Entrando...' : 'Entrar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Link Cadastro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Não tem uma conta? '),
                    GestureDetector(
                      onTap: () => _accountHelp(),
                      child: const Text(
                        'Registre-se',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
