import 'package:hive/hive.dart';

part 'deleted_transaction.g.dart';

@HiveType(typeId: 3)
class DeletedTransaction extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final DateTime originalDate;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int categoryIndex;

  @HiveField(4)
  final bool isIncome;

  @HiveField(5)
  final DateTime deletedAt;

  @HiveField(6)
  final double paidWithCash;

  @HiveField(7)
  final double paidWithBank;

  DeletedTransaction({
    required this.amount,
    required this.originalDate,
    required this.description,
    required this.categoryIndex,
    required this.isIncome,
    required this.deletedAt,
    required this.paidWithCash,
    required this.paidWithBank,
  });
}