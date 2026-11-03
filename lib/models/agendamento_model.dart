import 'tecnico_model.dart';
import 'contrato_model.dart';

class AgendamentoModel {
  final String id;
  final TecnicoModel tecnico;
  final ContratoModel contrato;
  final DateTime dataHora; // Guarda a data e o horário da visita técnica

  AgendamentoModel({
    required this.id,
    required this.tecnico,
    required this.contrato,
    required this.dataHora,
  });

  factory AgendamentoModel.fromMap(
    Map<String, Object?> map, {
    required TecnicoModel tecnico,
    required ContratoModel contrato,
  }) => AgendamentoModel(
    id: map['id'] as String,
    tecnico: tecnico,
    contrato: contrato,
    dataHora: DateTime.fromMillisecondsSinceEpoch(map['data_hora'] as int),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'tecnico_id': tecnico.id,
    'contrato_id': contrato.id,
    'data_hora': dataHora.millisecondsSinceEpoch,
  };
}
