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
      description: fields[1] as String,
      category: fields[2] as String,
      date: fields[3] as DateTime,
      isIncome: fields[4] as bool,
      paidWithCash: fields[5] as double,
      paidWithBank: fields[6] as double,
      paidWithBanks: (fields[7] as Map).cast<String, double>(),
      deletedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DeletedTransaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.isIncome)
      ..writeByte(5)
      ..write(obj.paidWithCash)
      ..writeByte(6)
      ..write(obj.paidWithBank)
      ..writeByte(7)
      ..write(obj.paidWithBanks)
      ..writeByte(8)
      ..write(obj.deletedAt);
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
