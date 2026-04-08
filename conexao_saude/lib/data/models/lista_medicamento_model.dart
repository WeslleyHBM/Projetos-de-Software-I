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
  @HiveField(3)
  final List<String> diasSemana;

  MedicamentoModel({
    required this.nome,
    required this.dose,
    required this.horario,
    required this.diasSemana,
  });
}

@HiveType(typeId: 1) // ID diferente para a lista
class ListaMedicamentoModel extends HiveObject {
  @HiveField(0)
  final String titulo; // Ex: "Remédios Pressão"

  @HiveField(1)
  final List<MedicamentoModel> medicamentos; // A lista de remédios dentro dela

  ListaMedicamentoModel({required this.titulo, required this.medicamentos});
}
