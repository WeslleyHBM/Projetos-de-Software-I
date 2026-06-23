import 'package:hive/hive.dart';

part 'lista_medicamento_model.g.dart';

@HiveType(typeId: 0)
class MedicamentoModel extends HiveObject {
  @HiveField(0)
  final String nome;
  @HiveField(1)
  final String dose;
  @HiveField(2)
  final String horario;
  @HiveField(3, defaultValue: 0)
  int diasConsumidos;
  @HiveField(4)
  final DateTime dataInicio;
  @HiveField(5)
  final DateTime dataFim;
  @HiveField(6)
  final int intervaloHoras;
  @HiveField(7)
  DateTime? ultimaDose;
  @HiveField(8, defaultValue: 0)
  int ofensivaAtual;
  @HiveField(9, defaultValue: 0)
  int maiorOfensiva;
  @HiveField(10)
  List<String> imageUrls;

  MedicamentoModel({
    required this.nome,
    required this.dose,
    required this.horario,
    this.diasConsumidos = 0,
    required this.dataInicio,
    required this.dataFim,
    required this.intervaloHoras,
    this.ultimaDose,
    this.ofensivaAtual = 0,
    this.maiorOfensiva = 0,
    this.imageUrls = const [],
  });

  /// Retorna o número de dias de duração do tratamento
  int get duracaoDias => dataFim.difference(dataInicio).inDays + 1;

  /// Verifica se o tratamento está ativo hoje
  bool get estaAtivoHoje {
    final agora = DateTime.now();
    final hojeInicio = DateTime(agora.year, agora.month, agora.day);
    final hojeFim = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);
    
    return dataInicio.isBefore(hojeFim) && dataFim.isAfter(hojeInicio);
  }
}

@HiveType(typeId: 1) // ID diferente para a lista
class ListaMedicamentoModel extends HiveObject {
  @HiveField(0)
  final String titulo; // Ex: "Remédios Pressão"

  @HiveField(1)
  final List<MedicamentoModel> medicamentos; // A lista de remédios dentro dela

  ListaMedicamentoModel({required this.titulo, required this.medicamentos});
}
