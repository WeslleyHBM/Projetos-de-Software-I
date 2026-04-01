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
    );
  }

  @override
  void write(BinaryWriter writer, MedicamentoModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.nome)
      ..writeByte(1)
      ..write(obj.dose)
      ..writeByte(2)
      ..write(obj.horario);
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
