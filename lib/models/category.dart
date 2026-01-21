import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category {
  dynamic key;

  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final String color;  // Cambiado de int a String
  
  @HiveField(2)
  final String icon;
  
  @HiveField(3)
  final bool isIncome;

  Category({
    required this.name,
    required this.color,  // Ahora acepta String
    required this.icon,
    required this.isIncome,
  });

  Future<void> save() async {
    if (key != null) {
      final box = await Hive.openBox<Category>('categories');
      await box.put(key, this);
      await box.flush();
    }
  }
}