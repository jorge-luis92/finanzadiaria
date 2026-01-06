// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_fixed_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ManualFixedExpenseAdapter extends TypeAdapter<ManualFixedExpense> {
  @override
  final int typeId = 5;

  @override
  ManualFixedExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ManualFixedExpense(
      name: fields[0] as String,
      amount: fields[1] as double,
      icon: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ManualFixedExpense obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualFixedExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
