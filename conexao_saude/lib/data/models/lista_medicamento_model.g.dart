// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lista_medicamento_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicamentoModelAdapter extends TypeAdapter<MedicamentoModel> {
  @override
  final int typeId = 0;

  @override
  MedicamentoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicamentoModel(
      nome: fields[0] as String,
      dose: fields[1] as String,
      horario: fields[2] as String,
      diasConsumidos: fields[3] == null ? 0 : fields[3] as int,
      dataInicio: fields[4] as DateTime,
      dataFim: fields[5] as DateTime,
      intervaloHoras: fields[6] as int,
      ultimaDose: fields[7] as DateTime?,
      ofensivaAtual: fields[8] == null ? 0 : fields[8] as int,
      maiorOfensiva: fields[9] == null ? 0 : fields[9] as int,
      imageUrls: (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MedicamentoModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.nome)
      ..writeByte(1)
      ..write(obj.dose)
      ..writeByte(2)
      ..write(obj.horario)
      ..writeByte(3)
      ..write(obj.diasConsumidos)
      ..writeByte(4)
      ..write(obj.dataInicio)
      ..writeByte(5)
      ..write(obj.dataFim)
      ..writeByte(6)
      ..write(obj.intervaloHoras)
      ..writeByte(7)
      ..write(obj.ultimaDose)
      ..writeByte(8)
      ..write(obj.ofensivaAtual)
      ..writeByte(9)
      ..write(obj.maiorOfensiva)
      ..writeByte(10)
      ..write(obj.imageUrls);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicamentoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ListaMedicamentoModelAdapter extends TypeAdapter<ListaMedicamentoModel> {
  @override
  final int typeId = 1;

  @override
  ListaMedicamentoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ListaMedicamentoModel(
      titulo: fields[0] as String,
      medicamentos: (fields[1] as List).cast<MedicamentoModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ListaMedicamentoModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.titulo)
      ..writeByte(1)
      ..write(obj.medicamentos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListaMedicamentoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
