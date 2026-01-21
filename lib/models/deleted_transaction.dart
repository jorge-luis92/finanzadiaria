import 'package:hive_flutter/hive_flutter.dart';
import 'transaction.dart'; // Agrega este import

part 'deleted_transaction.g.dart';

@HiveType(typeId: 3)
class DeletedTransaction {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String category; // Cambié de 'category' a 'categoryName' para evitar confusión

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final bool isIncome;

  @HiveField(5)
  final double paidWithCash;

  @HiveField(6)
  final double paidWithBank;

  @HiveField(7)
  final Map<String, double> paidWithBanks;

  @HiveField(8)
  final DateTime deletedAt;

  DeletedTransaction({
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.isIncome,
    required this.paidWithCash,
    required this.paidWithBank,
    required this.paidWithBanks,
    required this.deletedAt,
  });

  factory DeletedTransaction.fromTransaction(Transaction t, {required DateTime deletedAt}) {
    return DeletedTransaction(
      amount: t.amount,
      description: t.description,
      category: t.categoryIndex.toString(), // O usa un nombre real de categoría
      date: t.date,
      isIncome: t.isIncome,
      paidWithCash: t.paidWithCash,
      paidWithBank: t.paidWithBank,
      paidWithBanks: t.paidWithBanks ?? {},
      deletedAt: deletedAt,
    );
  }
}