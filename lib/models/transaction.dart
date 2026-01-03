import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String description;

  @HiveField(3)
  int categoryIndex;

  @HiveField(4)
  bool isIncome;

  @HiveField(5)
  double paidWithCash = 0.0;

  @HiveField(6)
  double paidWithBank = 0.0;

  Transaction({
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryIndex,
    required this.isIncome,
    this.paidWithCash = 0.0,
    this.paidWithBank = 0.0,
  });
}