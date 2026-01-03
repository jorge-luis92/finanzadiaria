import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/transaction.dart';
import 'models/category.dart';
import 'models/fixed_payment.dart';
import 'providers/finance_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(FixedPaymentAdapter());
  Hive.registerAdapter(DeletedTransactionAdapter()); // ← Ahora sí existe

  await Hive.openBox('settings');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<FixedPayment>('fixed_payments');
  await Hive.openBox<DeletedTransaction>('deleted_transactions'); // ← Ahora sí existe

  await initializeDateFormatting('es_MX', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider(),
      child: MaterialApp(
        title: 'FinanzaDiaria',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configured = Hive.box('settings').get('configured', defaultValue: false);
    return configured ? const HomeScreen() : const SetupScreen();
  }
}