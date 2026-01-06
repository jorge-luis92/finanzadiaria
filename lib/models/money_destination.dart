import 'package:hive/hive.dart';

part 'money_destination.g.dart';

@HiveType(typeId: 4)
class MoneyDestination extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount; // Monto fijo por período

  @HiveField(2)
  String icon;

  MoneyDestination({
    required this.name,
    required this.amount,
    this.icon = '👤',
  });
}