import 'package:hive/hive.dart';

part 'fixed_payment.g.dart';

@HiveType(typeId: 2)
class FixedPayment extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double totalAmount; // Deuda total o monto fijo

  @HiveField(2)
  double minimumPayment; // Pago mínimo mensual

  @HiveField(3)
  int cutDay; // Día de corte (1-31)

  @HiveField(4)
  int dueDay; // Día de pago límite (1-31)

  @HiveField(5)
  String icon; // Emoji o código

  FixedPayment({
    required this.name,
    required this.totalAmount,
    required this.minimumPayment,
    required this.cutDay,
    required this.dueDay,
    this.icon = '💳',
  });
}