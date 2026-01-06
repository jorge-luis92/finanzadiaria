import 'package:hive/hive.dart';

part 'bank_account.g.dart';

@HiveType(typeId: 6)
class BankAccount extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double balance;

  @HiveField(2)
  String icon;

  BankAccount({
    required this.name,
    required this.balance,
    this.icon = '🏦',
  });
}