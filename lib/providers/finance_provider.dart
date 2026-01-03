import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/fixed_payment.dart';
import '../models/deleted_transaction.dart';

class FinanceProvider extends ChangeNotifier {
  late Box settingsBox = Hive.box('settings');
  late Box<Transaction> transactionBox = Hive.box<Transaction>('transactions');
  late Box<Category> categoryBox = Hive.box<Category>('categories');
  late Box<FixedPayment> fixedPaymentsBox = Hive.box<FixedPayment>('fixed_payments');
  late Box<DeletedTransaction> deletedTransactionsBox = Hive.box<DeletedTransaction>('deleted_transactions');

  double dailyIncome = 0.0;
  String payFrequency = 'mensual';
  int daysWorkedPerPeriod = 22;
  double cashBalance = 0.0;
  List<double> bankBalances = [];
  DateTime? lastPayDate;

  bool hasSetCash = false;
  bool hasSetBank = false;

  List<Category> categories = [];
  List<FixedPayment> fixedPayments = [];
  List<DeletedTransaction> deletedTransactions = [];

  final DateFormat dateFormat = DateFormat('dd/MM/yyyy', 'es_MX');

  FinanceProvider() {
    _loadSettings();
    _loadCategories();
    loadFixedPayments();
    loadDeletedTransactions();
  }

  void _loadSettings() {
    dailyIncome = settingsBox.get('dailyIncome', defaultValue: 0.0);
    payFrequency = settingsBox.get('payFrequency', defaultValue: 'mensual');
    daysWorkedPerPeriod = settingsBox.get('daysWorkedPerPeriod', defaultValue: 22);

    if (settingsBox.containsKey('cashBalance')) {
      cashBalance = settingsBox.get('cashBalance', defaultValue: 0.0);
      hasSetCash = true;
    }
    if (settingsBox.containsKey('bankBalances')) {
      bankBalances = List<double>.from(settingsBox.get('bankBalances', defaultValue: <double>[]));
      hasSetBank = bankBalances.isNotEmpty;
    }

    final timestamp = settingsBox.get('lastPayDate');
    lastPayDate = timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  void saveIncomeConfig(double dailyIncomeValue, String frequency, int daysWorked) {
    dailyIncome = double.parse(dailyIncomeValue.toStringAsFixed(2));
    payFrequency = frequency;
    daysWorkedPerPeriod = daysWorked;

    settingsBox.put('dailyIncome', dailyIncome);
    settingsBox.put('payFrequency', frequency);
    settingsBox.put('daysWorkedPerPeriod', daysWorked);
    settingsBox.put('configured', true);

    notifyListeners();
  }

  void updateBalances({double? cash, double? bank}) {
    if (cash != null) {
      cashBalance = double.parse(cash.toStringAsFixed(2));
      settingsBox.put('cashBalance', cashBalance);
      hasSetCash = true;
    }
    if (bank != null) {
      bankBalances = [double.parse(bank.toStringAsFixed(2))];
      settingsBox.put('bankBalances', bankBalances);
      hasSetBank = true;
    }
    notifyListeners();
  }

  bool spend(double totalAmount, double fromCash, double fromBank) {
    final availableCash = cashBalance;
    final availableBank = bankBalances.isEmpty ? 0.0 : bankBalances[0];

    if (fromCash > availableCash + 0.01 || fromBank > availableBank + 0.01) return false;
    if ((fromCash + fromBank - totalAmount).abs() > 0.01) return false;

    cashBalance -= fromCash;
    if (bankBalances.isNotEmpty) bankBalances[0] -= fromBank;

    settingsBox.put('cashBalance', cashBalance);
    settingsBox.put('bankBalances', bankBalances);
    notifyListeners();
    return true;
  }

  int getDefaultDaysForPeriod() {
    if (payFrequency == 'quincenal') {
      final now = DateTime.now();
      if (now.day <= 15) return 15;
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      return lastDay - 15;
    }
    return {'semanal': 7, 'catorcena': 14, 'quincenal': 15, 'mensual': 30}[payFrequency] ?? 30;
  }

  double getExpectedPaycheck() => double.parse((dailyIncome * daysWorkedPerPeriod).toStringAsFixed(2));

  double getCurrentTotalBalance() => double.parse((cashBalance + bankBalances.fold(0.0, (a, b) => a + b)).toStringAsFixed(2));

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
    final total = getCurrentTotalBalance() + getTodayIncome() - getTodayExpenses();
    return total > 0 ? double.parse(total.toStringAsFixed(2)) : 0.0;
  }

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
    if (lastPayDate!.year != date.year || lastPayDate!.month != date.month) return 0;
    return 1;
  }

  void markPaymentReceived() {
    if (!canMarkPayment()) return;
    final paycheck = getExpectedPaycheck();
    cashBalance += paycheck;
    lastPayDate = DateTime.now();
    settingsBox.put('cashBalance', cashBalance);
    settingsBox.put('lastPayDate', lastPayDate!.millisecondsSinceEpoch);
    notifyListeners();
  }

  void cancelLastPayment() {
    if (lastPayDate == null) return;
    final paycheck = getExpectedPaycheck();
    cashBalance -= paycheck;
    if (cashBalance < 0) cashBalance = 0.0;
    lastPayDate = null;
    settingsBox.put('cashBalance', cashBalance);
    settingsBox.delete('lastPayDate');
    notifyListeners();
  }

  void _loadCategories() {
    if (categoryBox.isEmpty) {
      final defaults = [
        Category(name: 'Salario', icon: '💼', color: '#4CAF50', isIncome: true),
        Category(name: 'Otros ingresos', icon: '💰', color: '#8BC34A', isIncome: true),
        Category(name: 'Freelance', icon: '💻', color: '#66BB6A', isIncome: true),
        Category(name: 'Café/Snacks', icon: '☕', color: '#FF5722', isIncome: false),
        Category(name: 'Transporte', icon: '🚌', color: '#FF9800', isIncome: false),
        Category(name: 'Salidas', icon: '🍔', color: '#F44336', isIncome: false),
        Category(name: 'Luz', icon: '💡', color: '#2196F3', isIncome: false),
        Category(name: 'Internet', icon: '🌐', color: '#3F51B5', isIncome: false),
        Category(name: 'Supermercado', icon: '🛒', color: '#9C27B0', isIncome: false),
        Category(name: 'Tarjeta crédito', icon: '💳', color: '#E91E63', isIncome: false),
      ];
      for (var cat in defaults) {
        categoryBox.add(cat);
      }
    }
    categories = categoryBox.values.toList();
    notifyListeners();
  }

  void loadFixedPayments() {
    fixedPayments = fixedPaymentsBox.values.toList();
    notifyListeners();
  }

  void addFixedPayment(FixedPayment payment) {
    fixedPaymentsBox.add(payment);
    loadFixedPayments();
  }

  void updateFixedPayment(dynamic key, FixedPayment payment) {
    fixedPaymentsBox.put(key, payment);
    loadFixedPayments();
  }

  void deleteFixedPayment(dynamic key) {
    fixedPaymentsBox.delete(key);
    loadFixedPayments();
  }

  void loadDeletedTransactions() {
    deletedTransactions = deletedTransactionsBox.values.toList()
      ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    notifyListeners();
  }

  void addTransaction(
    double amount,
    String desc,
    int catIndex,
    bool isIncome, {
    double paidWithCash = 0.0,
    double paidWithBank = 0.0,
  }) {
    final trans = Transaction(
      amount: double.parse(amount.toStringAsFixed(2)),
      date: DateTime.now(),
      description: desc,
      categoryIndex: catIndex,
      isIncome: isIncome,
      paidWithCash: paidWithCash,
      paidWithBank: paidWithBank,
    );
    transactionBox.add(trans);
    notifyListeners();
  }

  Future<bool> deleteTransactionWithConfirmation(Transaction trans, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar transacción?'),
        content: Text(
          'Monto: \$${trans.amount.toStringAsFixed(2)}\n'
          '${trans.description.isEmpty ? categories[trans.categoryIndex].name : trans.description}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    // Guardar en eliminados
    final deleted = DeletedTransaction(
      amount: trans.amount,
      originalDate: trans.date,
      description: trans.description,
      categoryIndex: trans.categoryIndex,
      isIncome: trans.isIncome,
      deletedAt: DateTime.now(),
      paidWithCash: trans.paidWithCash,
      paidWithBank: trans.paidWithBank,
    );
    await deletedTransactionsBox.add(deleted);

    // Recuperar saldo
    if (!trans.isIncome) {
      cashBalance += trans.paidWithCash;
      if (bankBalances.isNotEmpty) bankBalances[0] += trans.paidWithBank;
      settingsBox.put('cashBalance', cashBalance);
      settingsBox.put('bankBalances', bankBalances);
    } else {
      cashBalance -= trans.amount;
      if (cashBalance < 0) cashBalance = 0.0;
      settingsBox.put('cashBalance', cashBalance);
    }

    await trans.delete();
    loadDeletedTransactions();
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transacción eliminada y saldo recuperado')),
    );

    return true;
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
    return Map.fromEntries(map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}