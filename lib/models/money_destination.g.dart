// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_destination.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoneyDestinationAdapter extends TypeAdapter<MoneyDestination> {
  @override
  final int typeId = 4;

  @override
  MoneyDestination read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoneyDestination(
      name: fields[0] as String,
      amount: fields[1] as double,
      icon: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MoneyDestination obj) {
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
      other is MoneyDestinationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
