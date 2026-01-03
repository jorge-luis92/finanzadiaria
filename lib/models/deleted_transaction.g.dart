// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeletedTransactionAdapter extends TypeAdapter<DeletedTransaction> {
  @override
  final int typeId = 3;

  @override
  DeletedTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeletedTransaction(
      amount: fields[0] as double,
      originalDate: fields[1] as DateTime,
      description: fields[2] as String,
      categoryIndex: fields[3] as int,
      isIncome: fields[4] as bool,
      deletedAt: fields[5] as DateTime,
      paidWithCash: fields[6] as double,
      paidWithBank: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DeletedTransaction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.originalDate)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.categoryIndex)
      ..writeByte(4)
      ..write(obj.isIncome)
      ..writeByte(5)
      ..write(obj.deletedAt)
      ..writeByte(6)
      ..write(obj.paidWithCash)
      ..writeByte(7)
      ..write(obj.paidWithBank);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletedTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
