import 'dart:typed_data';

// O modelo da interface nunca carrega a senha nem o hash da senha.
class UserModel {
  const UserModel({
    required this.id,
    required this.nome,
    required this.localTrabalho,
    required this.username,
    required this.role,
    this.foto,
    this.mustChangePassword = false,
  });
  final String id;
  final String nome;
  final String localTrabalho;
  final String username;
  final String role;
  final Uint8List? foto;
  final bool mustChangePassword;
  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, Object?> row) => UserModel(
    id: row['id'] as String,
    nome: row['nome'] as String,
    localTrabalho: row['local_trabalho'] as String,
    username: row['username'] as String,
    role: row['role'] as String,
    foto: row['foto'] == null
        ? null
        : Uint8List.fromList((row['foto'] as List).cast<int>()),
    mustChangePassword: row['trocar_senha'] == 1,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'nome': nome.trim(),
    'local_trabalho': localTrabalho.trim(),
    'username': username.trim().toLowerCase(),
    'role': role,
    'foto': foto,
    'trocar_senha': mustChangePassword ? 1 : 0,
  };
}
