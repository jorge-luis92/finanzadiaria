import 'package:hive/hive.dart';

part 'manual_fixed_expense.g.dart';

@HiveType(typeId: 5)
class ManualFixedExpense extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String icon;

  ManualFixedExpense({
    required this.name,
    required this.amount,
    this.icon = '🏠',
  });
}