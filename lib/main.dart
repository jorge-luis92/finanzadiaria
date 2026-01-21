// main.dart - VERSIÓN CORREGIDA
import 'dart:io';

import 'package:flutter/material.dart';
// REMUEVE esta línea: import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'services/notification_service.dart';

import 'models/transaction.dart';
import 'models/category.dart';
import 'models/fixed_payment.dart';
import 'models/deleted_transaction.dart';
import 'models/money_destination.dart';
import 'models/manual_fixed_expense.dart';
import 'models/bank_account.dart';
import 'providers/finance_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Directory dir;
  if (Platform.isAndroid) {
    dir = await getApplicationDocumentsDirectory(); 
  } else if (Platform.isIOS) {
    dir = await getLibraryDirectory();
  } else {
    dir = await getApplicationDocumentsDirectory();
  }

  await Hive.initFlutter(dir.path);
  // ====================================================================

  // Registrar adaptadores
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(FixedPaymentAdapter());
  Hive.registerAdapter(DeletedTransactionAdapter());
  Hive.registerAdapter(MoneyDestinationAdapter());
  Hive.registerAdapter(ManualFixedExpenseAdapter());
  Hive.registerAdapter(BankAccountAdapter());

  // Abrir boxes
  await Hive.openBox('settings');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<FixedPayment>('fixed_payments');
  await Hive.openBox<DeletedTransaction>('deleted_transactions');
  await Hive.openBox<MoneyDestination>('money_destinations');
  await Hive.openBox<ManualFixedExpense>('manual_fixed_expenses');
  await Hive.openBox<BankAccount>('bank_accounts');

  // Notificaciones y formato fecha
  await NotificationService.initialize();
  await initializeDateFormatting('es_MX', null);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.detached) {
      // Cuando la app va a segundo plano o está siendo cerrada
      _saveAllHiveBoxes();
    }
  }

  Future<void> _saveAllHiveBoxes() async {
    try {
      // Guardar todas las boxes de Hive
      await Hive.box('settings').flush();
      await Hive.box<Transaction>('transactions').flush();
      await Hive.box<Category>('categories').flush();
      await Hive.box<FixedPayment>('fixed_payments').flush();
      await Hive.box<DeletedTransaction>('deleted_transactions').flush();
      await Hive.box<MoneyDestination>('money_destinations').flush();
      await Hive.box<ManualFixedExpense>('manual_fixed_expenses').flush();
      await Hive.box<BankAccount>('bank_accounts').flush();
      
      print('✅ Todos los datos de Hive guardados correctamente');
    } catch (e) {
      print('❌ Error al guardar datos de Hive: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider()..schedulePaymentNotifications(),
      child: MaterialApp(
        title: 'FinanzaDiaria',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        // SOLUCIÓN SIMPLIFICADA - Sin localizaciones complejas
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