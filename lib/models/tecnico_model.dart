import 'dart:typed_data';

// Modelo que representa um Técnico da empresa
class TecnicoModel {
  final String id;
  final String nome;
  final String especialidade;
  final String telefone;
  final String fotoUrl;
  final Uint8List? foto;

  TecnicoModel({
    required this.id,
    required this.nome,
    required this.especialidade,
    required this.telefone,
    required this.fotoUrl,
    this.foto,
  });

  factory TecnicoModel.fromMap(Map<String, Object?> map) => TecnicoModel(
    id: map['id'] as String,
    nome: map['nome'] as String,
    especialidade: map['especialidade'] as String,
    telefone: map['telefone'] as String,
    fotoUrl: map['foto_url'] as String,
    foto: map['foto'] == null
        ? null
        : Uint8List.fromList((map['foto'] as List).cast<int>()),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'nome': nome,
    'especialidade': especialidade,
    'telefone': telefone,
    'foto_url': fotoUrl,
    'foto': foto,
  };
}
