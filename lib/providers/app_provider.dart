import '../repositories/user_repository.dart';
import '../utils/field_validators.dart';
import '../controllers/auth_controller.dart';
import '../data/app_database.dart';
import '../repositories/telefonia_repository.dart';
import '../repositories/crud_repository.dart';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/tecnico_model.dart';
import '../models/contrato_model.dart';
import '../models/agendamento_model.dart';

// Coordena a interface e mantém uma cópia dos dados persistidos no SQLite.
class AppProvider extends ChangeNotifier {
  AppProvider({TelefoniaRepository? repository, UserRepository? userRepository})
    : _repository = repository ?? TelefoniaRepository(AppDatabase()) {
    _userRepository = userRepository ?? UserRepository(_repository.database);
    _authController = AuthController(_userRepository);
  }

  late final UserRepository _userRepository;
  late final AuthController _authController;
  int _sessionVersion = 0;
  List<UserModel> _users = [];
  List<UserModel> get users => List.unmodifiable(_users);
  bool get isAdmin =>
      _currentUser?.isAdmin == true &&
      _currentUser?.mustChangePassword == false;

  final TelefoniaRepository _repository;
  List<TecnicoModel> _tecnicos = [];
  List<ContratoModel> _contratos = [];
  List<AgendamentoModel> _agendamentos = [];
  bool isLoading = true;
  bool isSaving = false;
  String? loadError;

  Future<void> initialize() async { // Inicializa o provider, carregando o banco de dados e os dados do usuário atual, tratando erros e notificando os ouvintes sobre o estado de carregamento.
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await _repository.database.database;
      if (_currentUser != null) await _reload();
    } catch (error, stack) {
      debugPrint('Falha ao carregar SQLite: $error\n$stack');
      loadError =
          'Não foi possível carregar o banco de dados. Tente novamente.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reload() async { // Recarrega os dados do usuário atual e as listas de técnicos, contratos e agendamentos, garantindo que a sessão ainda seja válida e tratando casos em que o usuário precisa alterar sua senha.
    final current = _currentUser;
    if (current == null) return;
    final session = _sessionVersion;
    final fresh = await _userRepository.findById(current.id);
    if (session != _sessionVersion) return;
    if (fresh == null || fresh.mustChangePassword) {
      _currentUser = fresh;
      _clearData();
      return;
    }
    final snapshot = await _repository.load();
    final users = fresh.isAdmin
        ? await _userRepository.list(fresh.id)
        : <UserModel>[];
    // Uma leitura que terminou após logout não pode restaurar a sessão anterior.
    if (session != _sessionVersion) return;
    _currentUser = fresh;
    _tecnicos = snapshot.tecnicos;
    _contratos = snapshot.contratos;
    _agendamentos = snapshot.agendamentos;
    _users = users;
  }

  Future<void> _save( // executa uma ação de salvamento de dados, garantindo que o usuário atual tenha acesso apropriado, tratando erros e notificando os ouvintes sobre o estado de salvamento.
    Future<void> Function() action, {
    bool admin = true,
    bool allowPasswordChange = false,
  }) async {
    final session = _sessionVersion;
    await _userRepository.requireAccess(
      _currentUser?.id,
      admin: admin,
      allowPasswordChange: allowPasswordChange,
    );
    if (session != _sessionVersion) {
      throw const RepositoryException(
        'A sessão foi encerrada. Entre novamente.',
      );
    }
    if (isSaving) throw const RepositoryException('Aguarde a operação atual.'); // Evita que múltiplas operações de salvamento ocorram simultaneamente, garantindo consistência dos dados.
    isSaving = true;
    notifyListeners();
    try {
      await action();
      await _reload();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // Usuário Atualmente Logado
  UserModel? _currentUser;

  // 
  List<TecnicoModel> get tecnicos => List<TecnicoModel>.unmodifiable(_tecnicos);
  List<ContratoModel> get contratos =>
      List<ContratoModel>.unmodifiable(_contratos);
  List<AgendamentoModel> get agendamentos =>
      List<AgendamentoModel>.unmodifiable(_agendamentos);
  UserModel? get currentUser => _currentUser;

// Tenta efetuar o login do usuário, validando as credenciais e carregando os dados do usuário atual, retornando o usuário autenticado ou null se a autenticação falhar.
  Future<UserModel?> login(String username, String password) async {
    final session = ++_sessionVersion;
    _currentUser = null;
    _clearData();
    final user = await _authController.authenticate(username, password);
    if (session != _sessionVersion) return null;
    _currentUser = user;
    if (user != null) await _reload();
    notifyListeners();
    return _currentUser;
  }

// Tenta efetuar o login do usuário, validando as credenciais e carregando os dados do usuário atual, retornando o usuário autenticado ou null se a autenticação falhar.
  void _clearData() {
    _tecnicos = [];
    _contratos = [];
    _agendamentos = [];
    _users = [];
  }

// Encerra a sessão do usuário atual, limpando os dados e notificando os ouvintes sobre a alteração de estado.
  void logout() {
    _sessionVersion++;
    _currentUser = null;
    _clearData();
    notifyListeners();
  }

// Salva os dados do usuário, validando os campos e chamando o método de salvamento do provider, exibindo mensagens de erro se necessário e redirecionando para a tela apropriada após o salvamento bem-sucedido.
  Future<void> saveUser(
    UserModel user, {
    String? password,
    bool creating = false,
  }) => _save(
    () => _userRepository.saveAsAdmin(
      _currentUser!.id,
      user,
      password: password,
      creating: creating,
    ),
  );

  // Exclui o usuário especificado, garantindo que o usuário atual tenha acesso apropriado, tratando erros e notificando os ouvintes sobre a alteração de estado.
  Future<void> deleteUser(String id) =>
      _save(() => _userRepository.delete(_currentUser!.id, id));
  Future<void> saveProfile(UserModel user) => _save(
    () => _userRepository.updateProfile(_currentUser!.id, user),
    admin: false,
  );
  Future<void> changePassword(String oldPassword, String newPassword) => _save(
    () => _userRepository.changePassword(
      _currentUser!.id,
      oldPassword,
      newPassword,
    ),
    admin: false,
    allowPasswordChange: true,
  );

// Valida os campos do técnico, lançando uma exceção se algum campo obrigatório estiver ausente ou se a foto exceder o tamanho máximo permitido.
  void _validateTecnico(TecnicoModel value) {
    final error =
        FieldValidators.requiredText(value.nome) ??
        FieldValidators.requiredText(value.especialidade) ??
        FieldValidators.phone(value.telefone);
    if (error != null) throw RepositoryException(error);
    if ((value.foto?.length ?? 0) > 2 * 1024 * 1024) {
      throw const RepositoryException('A foto deve ter até 2 MB.');
    }
  }

// Adiciona, atualiza ou remove técnicos, contratos e agendamentos, garantindo que o usuário atual tenha acesso apropriado, tratando erros e notificando os ouvintes sobre a alteração de estado.
  Future<void> addTecnico(TecnicoModel value) => _save(() async {
    _validateTecnico(value);
    await _repository.tecnicos.create(value);
  });
  Future<void> updateTecnico(TecnicoModel value) => _save(() async {
    _validateTecnico(value);
    await _repository.tecnicos.update(value);
  });
  Future<void> removeTecnico(String id) =>
      _save(() => _repository.tecnicos.delete(id));
  Future<void> addContrato(ContratoModel value) =>
      _save(() => _repository.contratos.create(value));
  Future<void> updateContrato(ContratoModel value) =>
      _save(() => _repository.contratos.update(value));
  Future<void> removeContrato(String id) =>
      _save(() => _repository.contratos.delete(id));
  Future<void> addAgendamento(AgendamentoModel value) =>
      _save(() => _repository.agendamentos.create(value));
  Future<void> updateAgendamento(AgendamentoModel value) =>
      _save(() => _repository.agendamentos.update(value));
  Future<void> removeAgendamento(String id) =>
      _save(() => _repository.agendamentos.delete(id));
}
