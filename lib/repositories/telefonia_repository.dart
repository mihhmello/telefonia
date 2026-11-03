import '../data/app_database.dart';
import '../models/tecnico_model.dart';
import '../models/contrato_model.dart';
import '../models/agendamento_model.dart';
import 'crud_repository.dart';

// Fornece métodos para acessar e manipular os dados de técnicos, contratos e agendamentos no banco de dados SQLite, garantindo consistência e integridade dos vínculos entre as entidades.
class TelefoniaSnapshot {
  const TelefoniaSnapshot(this.tecnicos, this.contratos, this.agendamentos);
  final List<TecnicoModel> tecnicos;
  final List<ContratoModel> contratos;
  final List<AgendamentoModel> agendamentos;
}

// Gerencia o acesso aos repositórios de técnicos, contratos e agendamentos, fornecendo métodos para carregar uma visão consistente dos dados e reconstruir os vínculos entre as entidades.
class TelefoniaRepository {
  TelefoniaRepository(this.database) {
    tecnicos = CrudRepository(
      database,
      'tecnicos',
      TecnicoModel.fromMap,
      (t) => t.toMap(),
      orderBy: 'nome COLLATE NOCASE',
    );
    contratos = CrudRepository(
      database,
      'contratos',
      ContratoModel.fromMap,
      (c) => c.toMap(),
      orderBy: 'numero_contrato COLLATE NOCASE',
    );
    agendamentos = CrudRepository(
      database,
      'agendamentos',
      (_) => throw UnsupportedError('Use load() para resolver os vínculos.'),
      (a) => a.toMap(),
      orderBy: 'data_hora',
    );
  }

// Retorna uma visão consistente dos dados de técnicos, contratos e agendamentos, reconstruindo os vínculos entre as entidades pelos IDs, garantindo que as alterações em técnicos ou contratos sejam refletidas nos agendamentos existentes.
  final AppDatabase database;
  late final CrudRepository<TecnicoModel> tecnicos;
  late final CrudRepository<ContratoModel> contratos;
  late final CrudRepository<AgendamentoModel> agendamentos;

  // Lê uma visão consistente e reconstrói os vínculos pelos IDs.
  // Assim, editar o técnico/contrato também atualiza as visitas existentes.
  Future<TelefoniaSnapshot> load() async {
    final db = await database.database;
    return db.transaction((txn) async {
      final tecnicos = (await txn.query(
        'tecnicos',
        orderBy: 'nome COLLATE NOCASE',
      )).map(TecnicoModel.fromMap).toList();
      final contratos = (await txn.query(
        'contratos',
        orderBy: 'numero_contrato COLLATE NOCASE',
      )).map(ContratoModel.fromMap).toList();
      final tecnicoPorId = {for (final t in tecnicos) t.id: t};
      final contratoPorId = {for (final c in contratos) c.id: c};
      final agendamentos =
          (await txn.query('agendamentos', orderBy: 'data_hora'))
              .map(
                (row) => AgendamentoModel.fromMap(
                  row,
                  tecnico: tecnicoPorId[row['tecnico_id']]!,
                  contrato: contratoPorId[row['contrato_id']]!,
                ),
              )
              .toList();
      return TelefoniaSnapshot(tecnicos, contratos, agendamentos);
    });
  }
}
