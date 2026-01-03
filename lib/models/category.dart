import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String icon;

  @HiveField(2)
  String color;

  @HiveField(3)
  bool isIncome;

  Category({
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
  });
}