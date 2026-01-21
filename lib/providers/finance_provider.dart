import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';

import '../models/transaction.dart';
import '../models/category.dart';
import '../models/fixed_payment.dart';
import '../models/deleted_transaction.dart';
import '../models/money_destination.dart';
import '../models/manual_fixed_expense.dart';
import '../models/bank_account.dart';
import '../services/notification_service.dart';

enum ChartType { pie, bar, line }

class FinanceProvider extends ChangeNotifier {
  // STREAM para forzar actualizaciones en release
  final StreamController<bool> _refreshController =
      StreamController<bool>.broadcast();
  Stream<bool> get refreshStream => _refreshController.stream;

  ChartType selectedChartType = ChartType.pie;

  // Método para cambiar tipo de gráfico
  void setChartType(ChartType type) {
    selectedChartType = type;
    settingsBox.put('selectedChartType', type.toString());
    _forceImmediateRefresh();
  }

  // Boxes de Hive
  late Box settingsBox;
  late Box<Transaction> transactionBox;
  late Box<Category> categoryBox;
  late Box<FixedPayment> fixedPaymentsBox;
  late Box<DeletedTransaction> deletedTransactionsBox;
  late Box<MoneyDestination> moneyDestinationsBox;
  late Box<ManualFixedExpense> manualFixedExpensesBox;
  late Box<BankAccount> bankAccountsBox;

  // Variables de configuración y estado
  double dailyIncome = 0.0;
  String payFrequency = 'mensual';
  int daysWorkedPerPeriod = 22;
  double cashBalance = 0.0;
  List<double> bankBalances = [];
  DateTime? lastPayDate;
  bool hasSetCash = false;
  bool hasSetBank = false;
  double savingsGoal = 0.0;
  bool saveInCash = true;

  // Listas en memoria
  List<Category> categories = [];
  List<FixedPayment> fixedPayments = [];
  List<DeletedTransaction> deletedTransactions = [];
  List<MoneyDestination> moneyDestinations = [];
  List<ManualFixedExpense> manualFixedExpenses = [];
  List<BankAccount> bankAccounts = [];

  // Formato de fecha
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy', 'es_MX');

  // Getters rápidos
  double get deductions => settingsBox.get('deductions', defaultValue: 0.0);

  set deductions(double value) {
    settingsBox.put('deductions', value);
    _saveAndRefresh();
  }

  FinanceProvider() {
    // Inicializar boxes
    settingsBox = Hive.box('settings');
    transactionBox = Hive.box<Transaction>('transactions');
    categoryBox = Hive.box<Category>('categories');
    fixedPaymentsBox = Hive.box<FixedPayment>('fixed_payments');
    deletedTransactionsBox = Hive.box<DeletedTransaction>(
      'deleted_transactions',
    );
    moneyDestinationsBox = Hive.box<MoneyDestination>('money_destinations');
    manualFixedExpensesBox = Hive.box<ManualFixedExpense>(
      'manual_fixed_expenses',
    );
    bankAccountsBox = Hive.box<BankAccount>('bank_accounts');

    // Cargar configuración de gráfico
    final savedChartType = settingsBox.get(
      'selectedChartType',
      defaultValue: 'ChartType.pie',
    );
    if (savedChartType == 'ChartType.bar') {
      selectedChartType = ChartType.bar;
    } else if (savedChartType == 'ChartType.line') {
      selectedChartType = ChartType.line;
    } else {
      selectedChartType = ChartType.pie;
    }

    // Cargar todo
    _loadSettings();
    _loadCategories();
    loadFixedPayments();
    loadDeletedTransactions();
    loadMoneyDestinations();
    loadManualFixedExpenses();
    loadBankAccounts();

    // Programar notificaciones iniciales
    schedulePaymentNotifications();

    // Forzar primer refresh
    _forceImmediateRefresh();
  }

  // MÉTODO NUEVO: Forzar refresh inmediato
  void _forceImmediateRefresh() {
    // Estrategia 1: NotifyListeners tradicional
    notifyListeners();

    // Estrategia 2: Stream para forzar rebuilds
    _refreshController.add(true);

    // Estrategia 3: Post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    // Estrategia 4: Microtask para asegurar
    Future.microtask(() {
      notifyListeners();
      Future.microtask(() => notifyListeners());
    });
  }

  // MÉTODO NUEVO: Guardar y refrescar inmediatamente
  Future<void> _saveAndRefresh() async {
    try {
      await settingsBox.flush();
      _forceImmediateRefresh();
    } catch (e) {
      print('❌ Error en _saveAndRefresh: $e');
    }
  }

  Future<void> flushSettings() async {
    try {
      await settingsBox.flush();
    } catch (e) {
      print('❌ Error flushSettings: $e');
    }
  }

  Future<void> flushTransactions() async {
    try {
      await transactionBox.flush();
    } catch (e) {
      print('❌ Error flushTransactions: $e');
    }
  }

  Future<void> _flushCategories() async {
    try {
      await categoryBox.flush();
    } catch (e) {
      print('❌ Error _flushCategories: $e');
    }
  }

  Future<void> _flushFixedPayments() async {
    try {
      await fixedPaymentsBox.flush();
    } catch (e) {
      print('❌ Error _flushFixedPayments: $e');
    }
  }

  Future<void> _flushDeletedTransactions() async {
    try {
      await deletedTransactionsBox.flush();
    } catch (e) {
      print('❌ Error _flushDeletedTransactions: $e');
    }
  }

  Future<void> _flushMoneyDestinations() async {
    try {
      await moneyDestinationsBox.flush();
    } catch (e) {
      print('❌ Error _flushMoneyDestinations: $e');
    }
  }

  Future<void> _flushManualFixedExpenses() async {
    try {
      await manualFixedExpensesBox.flush();
    } catch (e) {
      print('❌ Error _flushManualFixedExpenses: $e');
    }
  }

  Future<void> _flushBankAccounts() async {
    try {
      await bankAccountsBox.flush();
    } catch (e) {
      print('❌ Error _flushBankAccounts: $e');
    }
  }

  Future<void> flushAllBoxes() async {
    try {
      await flushSettings();
      await flushTransactions();
      await _flushCategories();
      await _flushFixedPayments();
      await _flushDeletedTransactions();
      await _flushMoneyDestinations();
      await _flushManualFixedExpenses();
      await _flushBankAccounts();
    } catch (e) {
      print('❌ Error al guardar boxes: $e');
    }
  }

  void _loadSettings() {
    dailyIncome = settingsBox.get('dailyIncome', defaultValue: 0.0);
    payFrequency = settingsBox.get('payFrequency', defaultValue: 'mensual');
    daysWorkedPerPeriod = settingsBox.get(
      'daysWorkedPerPeriod',
      defaultValue: 22,
    );

    if (settingsBox.containsKey('cashBalance')) {
      cashBalance = settingsBox.get('cashBalance', defaultValue: 0.0);
      hasSetCash = true;
    }

    if (settingsBox.containsKey('bankBalances')) {
      bankBalances = List<double>.from(
        settingsBox.get('bankBalances', defaultValue: <double>[]),
      );
      hasSetBank = bankBalances.isNotEmpty;
    }

    final timestamp = settingsBox.get('lastPayDate');
    lastPayDate = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;

    savingsGoal = settingsBox.get('savingsGoal', defaultValue: 0.0);
    saveInCash = settingsBox.get('saveInCash', defaultValue: true);

    _forceImmediateRefresh();
  }

  void saveIncomeConfig(
    double dailyIncomeValue,
    String frequency,
    int daysWorked,
  ) {
    dailyIncome = double.parse(dailyIncomeValue.toStringAsFixed(2));
    payFrequency = frequency;
    daysWorkedPerPeriod = daysWorked;

    settingsBox.put('dailyIncome', dailyIncome);
    settingsBox.put('payFrequency', frequency);
    settingsBox.put('daysWorkedPerPeriod', daysWorked);
    settingsBox.put('configured', true);

    _saveAndRefresh();
  }

  void setSavingsGoal(double goal, bool inCash) {
    savingsGoal = goal;
    saveInCash = inCash;
    settingsBox.put('savingsGoal', goal);
    settingsBox.put('saveInCash', inCash);
    _saveAndRefresh();
  }

  // MÉTODO MEJORADO: Actualizar saldo de efectivo
  void updateCashBalance(double newBalance) {
    // Validación: no permitir valores negativos
    if (newBalance < 0) newBalance = 0.0;
    if (newBalance.isNaN) newBalance = 0.0;

    cashBalance = newBalance;
    hasSetCash = true;
    settingsBox.put('cashBalance', cashBalance);
    settingsBox.put('hasSetCash', hasSetCash);

    _saveAndRefresh();
  }

  void updateBalances({double? cash, double? bank}) {
    if (cash != null) {
      if (cash < 0) cash = 0.0;
      if (cash.isNaN) cash = 0.0;
      cashBalance = double.parse(cash.toStringAsFixed(2));
      settingsBox.put('cashBalance', cashBalance);
      hasSetCash = true;
    }

    if (bank != null) {
      if (bank < 0) bank = 0.0;
      if (bank.isNaN) bank = 0.0;
      bankBalances = [double.parse(bank.toStringAsFixed(2))];
      settingsBox.put('bankBalances', bankBalances);
      hasSetBank = true;
    }

    _saveAndRefresh();
  }

  bool spend(double totalAmount, double fromCash, Map<int, double> bankUsage) {
    // Validaciones
    if (totalAmount <= 0) return false;
    if (fromCash < 0) fromCash = 0.0;

    double totalBankUse = bankUsage.values.fold(0.0, (a, b) => a + b);
    double totalUsed = fromCash + totalBankUse;

    if ((totalUsed - totalAmount).abs() > 0.01) {
      return false;
    }

    if (fromCash > cashBalance + 0.01) {
      return false;
    }

    for (var entry in bankUsage.entries) {
      if (entry.key < bankAccounts.length) {
        final bank = bankAccounts[entry.key];
        if (entry.value > bank.balance + 0.01) {
          return false;
        }
      } else {
        return false;
      }
    }

    try {
      // Descontar efectivo
      if (fromCash > 0) {
        cashBalance -= fromCash;
        cashBalance = double.parse(cashBalance.toStringAsFixed(2));
        settingsBox.put('cashBalance', cashBalance);
      }

      // Descontar de bancos
      for (var entry in bankUsage.entries) {
        final index = entry.key;
        final amount = entry.value;

        if (index < bankAccounts.length && amount > 0) {
          final bank = bankAccounts[index];
          bank.balance -= amount;
          bank.balance = double.parse(bank.balance.toStringAsFixed(2));

          final key = bank.key;
          if (key != null) {
            bankAccountsBox.put(key, bank);
          }
        }
      }

      // Guardar y refrescar inmediatamente
      Future.wait([settingsBox.flush(), bankAccountsBox.flush()]).then((_) {
        loadBankAccounts();
        _forceImmediateRefresh();
      });

      return true;
    } catch (e) {
      print('❌ Error en spend: $e');
      return false;
    }
  }

  int getDefaultDaysForPeriod() {
    if (payFrequency == 'quincenal') {
      final now = DateTime.now();
      if (now.day <= 15) return 15;
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      return lastDay - 15;
    }
    return {
          'semanal': 7,
          'catorcena': 14,
          'quincenal': 15,
          'mensual': 30,
        }[payFrequency] ??
        30;
  }

  double getExpectedPaycheck() =>
      double.parse((dailyIncome * daysWorkedPerPeriod).toStringAsFixed(2));

  // Saldo total actual
  double getCurrentTotalBalance() {
    double total = cashBalance;
    for (var b in bankBalances) total += b;
    for (var bank in bankAccounts) total += bank.balance;
    return double.parse(total.toStringAsFixed(2));
  }

  // Ingresos y gastos de hoy
  double getTodayIncome() {
    final today = DateTime.now();
    return transactionBox.values
        .where((t) => t.isIncome && _isSameDay(t.date, today))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTodayExpenses() {
    final today = DateTime.now();
    return transactionBox.values
        .where((t) => !t.isIncome && _isSameDay(t.date, today))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getAvailableToday() {
    return getCurrentTotalBalance();
  }

  // Verificar si se puede marcar pago recibido
  bool canMarkPayment() {
    if (lastPayDate == null) return true;
    final now = DateTime.now();
    switch (payFrequency) {
      case 'mensual':
        return now.month != lastPayDate!.month || now.year != lastPayDate!.year;
      case 'quincenal':
        return _countPaymentsInMonth(now) < 2;
      case 'catorcena':
        return now.difference(lastPayDate!).inDays >= 14;
      case 'semanal':
        return now.difference(lastPayDate!).inDays >= 7;
      default:
        return true;
    }
  }

  int _countPaymentsInMonth(DateTime date) {
    if (lastPayDate == null) return 0;
    if (lastPayDate!.year != date.year || lastPayDate!.month != date.month)
      return 0;
    return 1;
  }

  void markPaymentReceived() {
    if (!canMarkPayment()) return;

    final paycheck = getExpectedPaycheck();
    cashBalance += paycheck;
    lastPayDate = DateTime.now();

    settingsBox.put('cashBalance', cashBalance);
    settingsBox.put('lastPayDate', lastPayDate!.millisecondsSinceEpoch);

    _saveAndRefresh();
  }

  void cancelLastPayment() {
    if (lastPayDate == null) return;

    final paycheck = getExpectedPaycheck();
    cashBalance -= paycheck;
    if (cashBalance < 0) cashBalance = 0.0;
    lastPayDate = null;

    settingsBox.put('cashBalance', cashBalance);
    settingsBox.delete('lastPayDate');

    _saveAndRefresh();
  }

  void _loadCategories() {
    if (categoryBox.isEmpty) {
      final defaults = [
        Category(name: 'Salario', icon: '💼', color: '#4CAF50', isIncome: true),
        Category(
          name: 'Otros ingresos',
          icon: '💰',
          color: '#8BC34A',
          isIncome: true,
        ),
        Category(
          name: 'Freelance',
          icon: '💻',
          color: '#66BB6A',
          isIncome: true,
        ),
        Category(
          name: 'Snacks/Gastos Hormiga',
          icon: '☕',
          color: '#FF5722',
          isIncome: false,
        ),
        Category(
          name: 'Transporte',
          icon: '🚌',
          color: '#FF9800',
          isIncome: false,
        ),
        Category(
          name: 'Salidas',
          icon: '🍔',
          color: '#F44336',
          isIncome: false,
        ),
        Category(name: 'Luz', icon: '💡', color: '#2196F3', isIncome: false),
        Category(
          name: 'Internet',
          icon: '🌐',
          color: '#3F51B5',
          isIncome: false,
        ),
        Category(
          name: 'Supermercado',
          icon: '🛒',
          color: '#9C27B0',
          isIncome: false,
        ),
        Category(
          name: 'Tarjeta crédito',
          icon: '💳',
          color: '#E91E63',
          isIncome: false,
        ),
      ];
      for (var cat in defaults) {
        categoryBox.add(cat);
      }
      _flushCategories();
    }
    categories = categoryBox.values.toList();
    _forceImmediateRefresh();
  }

  void loadFixedPayments() {
    fixedPayments = fixedPaymentsBox.values.toList();
    _forceImmediateRefresh();
  }

  void addFixedPayment(FixedPayment payment) async {
    await fixedPaymentsBox.add(payment);
    await _flushFixedPayments();
    loadFixedPayments();
  }

  void updateFixedPayment(dynamic key, FixedPayment payment) async {
    await fixedPaymentsBox.put(key, payment);
    await _flushFixedPayments();
    loadFixedPayments();
  }

  void deleteFixedPayment(dynamic key) async {
    await fixedPaymentsBox.delete(key);
    await _flushFixedPayments();
    loadFixedPayments();
  }

  void loadDeletedTransactions() {
    deletedTransactions = deletedTransactionsBox.values.toList()
      ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    _forceImmediateRefresh();
  }

  void loadMoneyDestinations() {
    moneyDestinations = moneyDestinationsBox.values.toList();
    _forceImmediateRefresh();
  }

  void addMoneyDestination(MoneyDestination dest) async {
    await moneyDestinationsBox.add(dest);
    await _flushMoneyDestinations();
    loadMoneyDestinations();
  }

  void updateMoneyDestination(dynamic key, MoneyDestination dest) async {
    await moneyDestinationsBox.put(key, dest);
    await _flushMoneyDestinations();
    loadMoneyDestinations();
  }

  void deleteMoneyDestination(dynamic key) async {
    await moneyDestinationsBox.delete(key);
    await _flushMoneyDestinations();
    loadMoneyDestinations();
  }

  void loadManualFixedExpenses() {
    manualFixedExpenses = manualFixedExpensesBox.values.toList();
    _forceImmediateRefresh();
  }

  void addManualFixedExpense(ManualFixedExpense expense) async {
    await manualFixedExpensesBox.add(expense);
    await _flushManualFixedExpenses();
    loadManualFixedExpenses();
  }

  void updateManualFixedExpense(dynamic key, ManualFixedExpense expense) async {
    await manualFixedExpensesBox.put(key, expense);
    await _flushManualFixedExpenses();
    loadManualFixedExpenses();
  }

  void deleteManualFixedExpense(dynamic key) async {
    await manualFixedExpensesBox.delete(key);
    await _flushManualFixedExpenses();
    loadManualFixedExpenses();
  }

  void loadBankAccounts() {
    bankAccounts = bankAccountsBox.values.toList();
    _forceImmediateRefresh();
  }

  void addBankAccount(BankAccount account) async {
    // Validación: no permitir nombre vacío
    if (account.name.trim().isEmpty) {
      account.name = 'Banco ${bankAccounts.length + 1}';
    }

    // Validación: no permitir saldo negativo
    if (account.balance < 0) account.balance = 0.0;
    if (account.balance.isNaN) account.balance = 0.0;

    await bankAccountsBox.add(account);
    await _flushBankAccounts();
    loadBankAccounts();
    _forceImmediateRefresh();
  }

  void updateBankAccount(dynamic key, BankAccount account) async {
    // Validación: no permitir saldo negativo
    if (account.balance < 0) account.balance = 0.0;
    if (account.balance.isNaN) account.balance = 0.0;

    await bankAccountsBox.put(key, account);
    await _flushBankAccounts();
    loadBankAccounts();
    _forceImmediateRefresh();
  }

  void deleteBankAccount(dynamic key) async {
    await bankAccountsBox.delete(key);
    await _flushBankAccounts();
    loadBankAccounts();
    _forceImmediateRefresh();
  }

  void addTransactionWithDate(
    double amount,
    String desc,
    int catIndex,
    bool isIncome,
    DateTime date, {
    double paidWithCash = 0.0,
    double paidWithBank = 0.0,
    Map<String, double> paidWithBanks = const {},
  }) async {
    // Validaciones
    if (amount < 0) amount = 0.0;
    if (amount.isNaN) amount = 0.0;
    if (paidWithCash < 0) paidWithCash = 0.0;
    if (paidWithBank < 0) paidWithBank = 0.0;

    final trans = Transaction(
      amount: double.parse(amount.toStringAsFixed(2)),
      date: date,
      description: desc,
      categoryIndex: catIndex,
      isIncome: isIncome,
      paidWithCash: paidWithCash,
      paidWithBank: paidWithBank,
      paidWithBanks: paidWithBanks,
    );

    final key = await transactionBox.add(trans);
    // Crear con key asignado
    final transWithKey = Transaction(
      amount: trans.amount,
      date: trans.date,
      description: trans.description,
      categoryIndex: trans.categoryIndex,
      isIncome: trans.isIncome,
      paidWithCash: trans.paidWithCash,
      paidWithBank: trans.paidWithBank,
      paidWithBanks: trans.paidWithBanks,
      key: key,
    );

    await transactionBox.put(key, transWithKey);
    await flushTransactions();

    if (isIncome) {
      cashBalance += amount;
      settingsBox.put('cashBalance', cashBalance);
      await flushSettings();
    }

    loadBankAccounts();
    _forceImmediateRefresh();
  }

  Future<void> deleteTransactionImmediately(
    Transaction trans,
    BuildContext context,
  ) async {
    try {
      final transactionKey = trans.key;
      if (transactionKey == null) {
        return;
      }

      // 1. Guardar en eliminadas
      final deleted = DeletedTransaction(
        amount: trans.amount,
        date: trans.date,
        description: trans.description,
        category: categories[trans.categoryIndex].name,
        isIncome: trans.isIncome,
        deletedAt: DateTime.now(),
        paidWithCash: trans.paidWithCash,
        paidWithBank: trans.paidWithBank,
        paidWithBanks: trans.paidWithBanks,
      );
      await deletedTransactionsBox.add(deleted);
      await _flushDeletedTransactions();

      // 2. Actualizar saldos (REVERTIR)
      if (!trans.isIncome) {
        if (trans.paidWithCash > 0) {
          cashBalance += trans.paidWithCash;
          settingsBox.put('cashBalance', cashBalance);
        }

        for (var entry in trans.paidWithBanks.entries) {
          final bankName = entry.key;
          final amount = entry.value;
          final bank = bankAccounts.firstWhereOrNull((b) => b.name == bankName);
          if (bank != null) {
            bank.balance += amount;
            await bankAccountsBox.put(bank.key, bank);
          }
        }

        if (trans.paidWithBanks.isEmpty && trans.paidWithBank > 0) {
          cashBalance += trans.paidWithBank;
          settingsBox.put('cashBalance', cashBalance);
        }
      } else {
        cashBalance -= trans.amount;
        if (cashBalance < 0) cashBalance = 0.0;
        settingsBox.put('cashBalance', cashBalance);
      }

      // 3. Eliminar la transacción
      await transactionBox.delete(transactionKey);
      await flushTransactions();

      // 4. Guardar todos los cambios
      await Future.wait([settingsBox.flush(), bankAccountsBox.flush()]);

      // 5. Actualizar listas
      loadDeletedTransactions();
      loadBankAccounts();

      // 6. Forzar refresh
      _forceImmediateRefresh();

      // 7. Mostrar mensaje
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción eliminada'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error eliminando transacción: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool> deleteTransactionWithConfirmation(
    Transaction trans,
    BuildContext context,
  ) async {
    final transactionKey = trans.key;
    if (transactionKey == null) {
      return false;
    }

    final existingTransaction = transactionBox.get(transactionKey);
    if (existingTransaction == null) {
      return false;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar transacción?'),
        content: Text(
          'Monto: \$${trans.amount.toStringAsFixed(2)}\n'
          '${trans.description.isEmpty ? categories[trans.categoryIndex].name : trans.description}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    try {
      // 1. Guardar en eliminadas
      final deleted = DeletedTransaction(
        amount: trans.amount,
        date: trans.date,
        description: trans.description,
        category: categories[trans.categoryIndex].name,
        isIncome: trans.isIncome,
        deletedAt: DateTime.now(),
        paidWithCash: trans.paidWithCash,
        paidWithBank: trans.paidWithBank,
        paidWithBanks: trans.paidWithBanks,
      );
      await deletedTransactionsBox.add(deleted);
      await _flushDeletedTransactions();

      // 2. Actualizar saldos
      if (!trans.isIncome) {
        if (trans.paidWithCash > 0) {
          cashBalance += trans.paidWithCash;
          settingsBox.put('cashBalance', cashBalance);
        }

        trans.paidWithBanks.forEach((bankName, amount) async {
          final bank = bankAccounts.firstWhereOrNull((b) => b.name == bankName);
          if (bank != null) {
            bank.balance += amount;
            await bankAccountsBox.put(bank.key, bank);
          }
        });

        if (trans.paidWithBanks.isEmpty && trans.paidWithBank > 0) {
          cashBalance += trans.paidWithBank;
          settingsBox.put('cashBalance', cashBalance);
        }
      } else {
        if (trans.amount > 0) {
          cashBalance -= trans.amount;
          if (cashBalance < 0) cashBalance = 0.0;
          settingsBox.put('cashBalance', cashBalance);
        }
      }

      // 3. ELIMINAR LA TRANSACCIÓN
      await transactionBox.delete(transactionKey);
      await flushTransactions();

      // 4. Actualizar listas
      loadDeletedTransactions();
      loadBankAccounts();

      // 5. Forzar un rebuild
      _forceImmediateRefresh();

      // 6. Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción eliminada y saldo recuperado'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      print('❌ Error eliminando transacción: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
  }

  Future<void> schedulePaymentNotifications() async {
    await NotificationService.cancelAll();
    final now = DateTime.now();
    for (var payment in fixedPayments) {
      DateTime dueDate = DateTime(now.year, now.month, payment.dueDay);
      if (dueDate.isBefore(now)) {
        dueDate = DateTime(
          now.year + (now.month == 12 ? 1 : 0),
          (now.month % 12) + 1,
          payment.dueDay,
        );
      }
      final notifyDate = dueDate.subtract(const Duration(days: 3));
      if (notifyDate.isAfter(now)) {
        await NotificationService.schedulePaymentNotification(
          payment.key.hashCode,
          '¡Recordatorio de pago!',
          '${payment.name}: \$${payment.minimumPayment.toStringAsFixed(2)} vence el ${payment.dueDay}',
          notifyDate,
        );
      }
    }
  }

  List<Transaction> getAllTransactions() {
    final box = Hive.box<Transaction>('transactions');
    return box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Transaction> getTransactionsByMonth(int month, int year) {
    return transactionBox.values
        .where((t) => t.date.month == month && t.date.year == year)
        .toList();
  }

  double getAverageDailyExpense() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final gastos = transactionBox.values
        .where((t) => !t.isIncome && t.date.isAfter(thirtyDaysAgo))
        .fold(0.0, (sum, t) => sum + t.amount);
    return gastos / 30;
  }

  double getProjectedSavings() {
    return dailyIncome * daysWorkedPerPeriod - deductions - savingsGoal;
  }

  void resetAllData() async {
    await transactionBox.clear();
    await categoryBox.clear();
    await fixedPaymentsBox.clear();
    await deletedTransactionsBox.clear();
    await moneyDestinationsBox.clear();
    await manualFixedExpensesBox.clear();
    await bankAccountsBox.clear();
    await settingsBox.clear();

    await flushAllBoxes();

    _loadSettings();
    _forceImmediateRefresh();
  }

  void restoreDeletedTransaction(DeletedTransaction deleted) async {
    try {
      final catIndex = categories.indexWhere(
        (cat) => cat.name == deleted.category,
      );
      if (catIndex == -1) {
        return;
      }

      final trans = Transaction(
        amount: deleted.amount,
        date: deleted.date,
        description: deleted.description,
        categoryIndex: catIndex,
        isIncome: deleted.isIncome,
        paidWithCash: deleted.paidWithCash,
        paidWithBank: deleted.paidWithBank,
        paidWithBanks: deleted.paidWithBanks,
      );

      final key = await transactionBox.add(trans);
      trans.key = key;
      await transactionBox.put(key, trans);
      await flushTransactions();

      if (!deleted.isIncome) {
        if (deleted.paidWithCash > 0) {
          cashBalance -= deleted.paidWithCash;
          settingsBox.put('cashBalance', cashBalance);
        }

        for (var entry in deleted.paidWithBanks.entries) {
          final bankName = entry.key;
          final amount = entry.value;
          final bank = bankAccounts.firstWhereOrNull((b) => b.name == bankName);
          if (bank != null) {
            bank.balance -= amount;
            await bankAccountsBox.put(bank.key, bank);
          }
        }

        if (deleted.paidWithBanks.isEmpty && deleted.paidWithBank > 0) {
          cashBalance -= deleted.paidWithBank;
          settingsBox.put('cashBalance', cashBalance);
        }
      } else {
        cashBalance += deleted.amount;
        settingsBox.put('cashBalance', cashBalance);
      }

      final deletedEntry = deletedTransactionsBox.values.toList().firstWhere(
        (d) =>
            d.deletedAt == deleted.deletedAt &&
            d.amount == deleted.amount &&
            d.description == deleted.description,
        orElse: () => DeletedTransaction(
          amount: 0,
          date: DateTime.now(),
          description: '',
          category: '',
          isIncome: false,
          deletedAt: DateTime.now(),
          paidWithCash: 0,
          paidWithBank: 0,
          paidWithBanks: {},
        ),
      );

      if (deletedEntry.amount > 0) {
        final deletedKey = deletedTransactionsBox.keyAt(
          deletedTransactionsBox.values.toList().indexOf(deletedEntry),
        );
        await deletedTransactionsBox.delete(deletedKey);
        await _flushDeletedTransactions();
      }

      loadDeletedTransactions();
      loadBankAccounts();
      _forceImmediateRefresh();
    } catch (e) {
      print('❌ Error restaurando transacción: $e');
    }
  }

  List<Transaction> getRecentTransactions() {
    final list = transactionBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Map<String, double> getExpensesByCategoryLast30Days() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    Map<String, double> map = {};
    for (var t in transactionBox.values) {
      if (!t.isIncome && t.date.isAfter(cutoff)) {
        final catName = categories[t.categoryIndex].name;
        map[catName] = (map[catName] ?? 0) + t.amount;
      }
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  void updateTotals() {
    _forceImmediateRefresh();
    loadFixedPayments();
    loadMoneyDestinations();
    loadManualFixedExpenses();
    loadBankAccounts();
    loadDeletedTransactions();
  }

  DateTime getStartOfPeriod() {
    final now = DateTime.now();
    switch (payFrequency) {
      case 'semanal':
        // Lunes de la semana actual
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case 'catorcena':
        return now.day <= 15
            ? DateTime(now.year, now.month, 1)
            : DateTime(now.year, now.month, 15);
      case 'quincenal':
        return now.day <= 15
            ? DateTime(now.year, now.month, 1)
            : DateTime(now.year, now.month, 16);
      case 'mensual':
        return DateTime(now.year, now.month, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  // Método para obtener transacciones del período actual
  List<Transaction> getTransactionsForCurrentPeriod() {
    final startOfPeriod = getStartOfPeriod();
    return transactionBox.values
        .where(
          (t) =>
              t.date.isAfter(startOfPeriod) ||
              t.date.isAtSameMomentAs(startOfPeriod),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Método para obtener gastos variables del período actual
  double getVariableExpensesForCurrentPeriod() {
    final startOfPeriod = getStartOfPeriod();
    return transactionBox.values
        .where(
          (t) =>
              !t.isIncome &&
              (t.date.isAfter(startOfPeriod) ||
                  t.date.isAtSameMomentAs(startOfPeriod)),
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Método para obtener ingresos del período actual
  double getIncomeForCurrentPeriod() {
    final startOfPeriod = getStartOfPeriod();
    return transactionBox.values
        .where(
          (t) =>
              t.isIncome &&
              (t.date.isAfter(startOfPeriod) ||
                  t.date.isAtSameMomentAs(startOfPeriod)),
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Método para forzar recarga de todas las pantallas
  void forceFullRefresh() {
    // Recargar todas las listas
    _loadSettings();
    _loadCategories();
    loadFixedPayments();
    loadMoneyDestinations();
    loadManualFixedExpenses();
    loadBankAccounts();
    loadDeletedTransactions();

    // Forzar refresh completo
    _forceImmediateRefresh();
  }

  List<Map<String, dynamic>> getDailyExpensesLast7Days() {
    List<Map<String, dynamic>> data = [];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      double total = 0.0;
      for (var t in transactionBox.values) {
        if (!t.isIncome && _isSameDay(t.date, day)) total += t.amount;
      }
      data.add({
        'day': dateFormat.format(day).substring(0, 5),
        'amount': double.parse(total.toStringAsFixed(2)),
      });
    }
    return data;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Dispose para limpiar el stream
  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }
}
