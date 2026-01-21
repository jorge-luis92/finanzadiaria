import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction {
  @HiveField(8) // Agregar este campo como HiveField
  dynamic key;

  @HiveField(0)
  final double amount;
  
  @HiveField(1)
  final DateTime date;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final int categoryIndex;
  
  @HiveField(4)
  final bool isIncome;
  
  @HiveField(5)
  final double paidWithCash;
  
  @HiveField(6)
  final double paidWithBank;
  
  @HiveField(7)
  final Map<String, double> paidWithBanks;
  
  Transaction({
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryIndex,
    required this.isIncome,
    required this.paidWithCash,
    required this.paidWithBank,
    required this.paidWithBanks,
    this.key, // Hacer el key opcional en el constructor
  });

  // Método para guardar la transacción
  Future<void> save() async {
    if (key != null) {
      final box = await Hive.openBox<Transaction>('transactions');
      await box.put(key, this);
      await box.flush();
    }
  }

  // Método para eliminar la transacción
  Future<void> delete() async {
    if (key != null) {
      final box = await Hive.openBox<Transaction>('transactions');
      await box.delete(key);
      await box.flush();
    }
  }
}