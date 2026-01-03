// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_payment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FixedPaymentAdapter extends TypeAdapter<FixedPayment> {
  @override
  final int typeId = 2;

  @override
  FixedPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FixedPayment(
      name: fields[0] as String,
      totalAmount: fields[1] as double,
      minimumPayment: fields[2] as double,
      cutDay: fields[3] as int,
      dueDay: fields[4] as int,
      icon: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FixedPayment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.totalAmount)
      ..writeByte(2)
      ..write(obj.minimumPayment)
      ..writeByte(3)
      ..write(obj.cutDay)
      ..writeByte(4)
      ..write(obj.dueDay)
      ..writeByte(5)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
