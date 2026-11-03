// Modelo que representa um Contrato Telefônico
class ContratoModel {
  final String id;
  final String numeroContrato;
  final String cliente;
  final String plano;
  final String endereco;

  ContratoModel({
    required this.id,
    required this.numeroContrato,
    required this.cliente,
    required this.plano,
    required this.endereco,
  });

  factory ContratoModel.fromMap(Map<String, Object?> map) => ContratoModel(
    id: map['id'] as String,
    numeroContrato: map['numero_contrato'] as String,
    cliente: map['cliente'] as String,
    plano: map['plano'] as String,
    endereco: map['endereco'] as String,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'numero_contrato': numeroContrato,
    'cliente': cliente,
    'plano': plano,
    'endereco': endereco,
  };
}
