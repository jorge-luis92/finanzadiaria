import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/finance_provider.dart';
import 'setup_screen.dart';
import 'fixed_payments_screen.dart';
import 'deleted_transactions_screen.dart';
import 'quincenal_summary_screen.dart';
import '../models/bank_account.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.schedulePaymentNotifications();
        });
        final available = provider.getAvailableToday();
        final dailyRef = provider.dailyIncome;
        final showAlert = available < dailyRef && available > 0 && dailyRef > 0;

        final expensesByCat = provider.getExpensesByCategoryLast30Days();
        final totalExpenses30Days = expensesByCat.values.fold(
          0.0,
          (a, b) => a + b,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('FinanzaDiaria'),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet),
                tooltip: 'Configurar saldos actuales',
                onPressed: () => _showBalanceSetupDialog(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Cancelar último pago recibido',
                color: provider.lastPayDate != null
                    ? Colors.orange
                    : Colors.grey,
                onPressed: provider.lastPayDate != null
                    ? () => _confirmCancelPayment(context, provider)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.payment),
                tooltip: 'Marcar pago recibido',
                color: provider.canMarkPayment() ? Colors.blue : Colors.grey,
                onPressed: provider.canMarkPayment()
                    ? () => _confirmPayment(
                        context,
                        provider,
                        provider.getExpectedPaycheck(),
                      )
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.credit_card),
                tooltip: 'Pagos fijos y tarjetas de crédito',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FixedPaymentsScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Ver transacciones eliminadas',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeletedTransactionsScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configuración inicial',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SetupScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.summarize),
                tooltip: 'Resumen Quincenal',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuincenalSummaryScreen(),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 10,
                  color: showAlert ? Colors.red.withOpacity(0.12) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const Text(
                          'Total disponible hoy',
                          style: TextStyle(fontSize: 24, color: Colors.grey),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '\$${available.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: available >= dailyRef
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        if (showAlert)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              '¡Cuidado! Estás gastando más que tu ingreso diario de referencia',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const Divider(height: 40),
                        _buildInfoRow(
                          'Saldo actual total',
                          provider.getCurrentTotalBalance(),
                        ),
                        _buildInfoRow(
                          'Ingreso diario (control)',
                          provider.dailyIncome,
                        ),
                        _buildInfoRow(
                          'Próximo pago esperado',
                          provider.getExpectedPaycheck(),
                        ),
                        if (provider.lastPayDate != null)
                          _buildInfoRow(
                            'Último pago recibido',
                            0,
                            date: provider.dateFormat.format(
                              provider.lastPayDate!,
                            ),
                          ),
                        _buildInfoRow(
                          'Ingresos extra hoy',
                          provider.getTodayIncome(),
                          positive: true,
                        ),
                        _buildInfoRow(
                          'Gastado hoy',
                          provider.getTodayExpenses(),
                          positive: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                const Text(
                  'En qué más gasté (últimos 30 días)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                totalExpenses30Days == 0
                    ? const Center(
                        child: Text(
                          'Aún no hay gastos registrados en los últimos 30 días',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : SizedBox(
                        height: 320,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                            sections: expensesByCat.entries.take(6).map((e) {
                              final index = expensesByCat.keys.toList().indexOf(
                                e.key,
                              );
                              final percentage = totalExpenses30Days > 0
                                  ? (e.value / totalExpenses30Days * 100)
                                  : 0;
                              return PieChartSectionData(
                                value: e.value,
                                title:
                                    '${percentage.toStringAsFixed(0)}%\n${e.key}',
                                color: Colors
                                    .primaries[index % Colors.primaries.length],
                                radius: 90,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                const SizedBox(height: 30),

                const Text(
                  'Tendencia de gastos diarios (últimos 7 días)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final data = provider.getDailyExpensesLast7Days();
                              if (value.toInt() < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    data[value.toInt()]['day'],
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: provider
                              .getDailyExpensesLast7Days()
                              .asMap()
                              .entries
                              .map((e) {
                                return FlSpot(
                                  e.key.toDouble(),
                                  e.value['amount'],
                                );
                              })
                              .toList(),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Historial completo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                provider.getRecentTransactions().isEmpty
                    ? const Center(
                        child: Text(
                          'Aún no hay transacciones registradas',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.getRecentTransactions().length,
                        itemBuilder: (context, i) {
                          final t = provider.getRecentTransactions()[i];
                          final cat = provider.categories[t.categoryIndex];
                          return Dismissible(
                            key: Key(t.key.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await provider
                                  .deleteTransactionWithConfirmation(
                                    t,
                                    context,
                                  );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Text(
                                  cat.icon,
                                  style: const TextStyle(fontSize: 36),
                                ),
                                title: Text(
                                  t.description.isEmpty
                                      ? cat.name
                                      : t.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  provider.dateFormat.format(t.date),
                                ),
                                trailing: Text(
                                  '${t.isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: t.isIncome
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: () => _showAddTransactionDialog(context, provider),
            child: const Icon(Icons.add, size: 36),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    double amount, {
    bool positive = false,
    String? date,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            date ?? '${positive ? '+' : ''}\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: positive
                  ? Colors.green
                  : (date != null ? Colors.blueGrey : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showBalanceSetupDialog(BuildContext context, FinanceProvider provider) {
    final cashController = TextEditingController(
      text: provider.hasSetCash ? provider.cashBalance.toStringAsFixed(2) : '',
    );

    // Controladores con saldo actual de cada banco
    final bankControllers = provider.bankAccounts.map((account) {
      return TextEditingController(text: account.balance.toStringAsFixed(2));
    }).toList();

    final newBankNameController = TextEditingController();
    final newBankBalanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Configurar saldos actuales'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cashController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Efectivo en mano',
                        hintText: 'Ej. 1000.00',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cuentas bancarias',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...provider.bankAccounts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final account = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: bankControllers[i],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: '${account.icon} ${account.name}',
                            hintText: 'Ej. 1500.00',
                          ),
                        ),
                      );
                    }).toList(),

                    // Tu sección de agregar nueva cuenta (ya la tienes)
                    const Divider(height: 32),
                    const Text(
                      'Agregar nueva cuenta bancaria',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newBankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del banco / app',
                        hintText: 'Ej. Nu, BBVA, Santander',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newBankBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Saldo inicial',
                        prefixText: '\$ ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Guardar efectivo
                    final cashText = cashController.text
                        .replaceAll(',', '.')
                        .trim();
                    if (cashText.isNotEmpty) {
                      final cash = double.tryParse(cashText);
                      if (cash != null) provider.updateCashBalance(cash);
                    }

                    // Guardar bancos existentes
                    for (var i = 0; i < provider.bankAccounts.length; i++) {
                      final text = bankControllers[i].text
                          .replaceAll(',', '.')
                          .trim();
                      if (text.isNotEmpty) {
                        final value = double.tryParse(text);
                        if (value != null) {
                          final account = provider.bankAccounts[i];
                          account.balance = value;
                          provider.updateBankAccount(account.key, account);
                        }
                      }
                    }

                    // Agregar nueva cuenta (tu código existente)
                    final newName = newBankNameController.text.trim();
                    final newBalanceText = newBankBalanceController.text
                        .replaceAll(',', '.')
                        .trim();
                    if (newName.isNotEmpty && newBalanceText.isNotEmpty) {
                      final newBalance = double.tryParse(newBalanceText);
                      if (newBalance != null) {
                        provider.addBankAccount(
                          BankAccount(name: newName, balance: newBalance),
                        );
                      }
                    }

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saldos actualizados correctamente'),
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmPayment(
    BuildContext context,
    FinanceProvider provider,
    double amount,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Confirmar pago de nómina?'),
        content: Text(
          'Se agregará \$${amount.toStringAsFixed(2)} a tu saldo en efectivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.markPaymentReceived();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '¡Pago de \$${amount.toStringAsFixed(2)} recibido!',
                  ),
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelPayment(BuildContext context, FinanceProvider provider) {
    final amount = provider.getExpectedPaycheck();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar último pago recibido?'),
        content: Text(
          'Se restará \$${amount.toStringAsFixed(2)} de tu saldo actual.',
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.cancelLastPayment();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Último pago cancelado')),
              );
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(
    BuildContext context,
    FinanceProvider provider,
  ) {
    double totalAmount = 0.0;
    double fromCash = 0.0;
    Map<int, double> bankUsage =
        {}; // clave = índice de bankAccounts, valor = monto
    String desc = '';
    int selectedCat = 3; // Gasto Hormiga por defecto
    bool isIncome = false;
    String paymentMode = 'efectivo';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final availableCash = provider.cashBalance;
            final availableBanks = provider.bankAccounts;

            return AlertDialog(
              title: Text(isIncome ? 'Nuevo ingreso' : 'Nuevo gasto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto total',
                        hintText: 'Ej. 150.50',
                      ),
                      onChanged: (v) {
                        totalAmount =
                            double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                        setStateDialog(() {});
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                      ),
                      onChanged: (v) => desc = v,
                    ),
                    DropdownButton<int>(
                      isExpanded: true,
                      value: selectedCat,
                      hint: const Text('Categoría'),
                      items: provider.categories.asMap().entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text('${e.value.icon} ${e.value.name}'),
                        );
                      }).toList(),
                      onChanged: (v) => setStateDialog(() => selectedCat = v!),
                    ),
                    ListTile(
                      title: const Text('Fecha'),
                      subtitle: Text(provider.dateFormat.format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null)
                          setStateDialog(() => selectedDate = picked);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Es ingreso'),
                      value: isIncome,
                      onChanged: (v) => setStateDialog(() => isIncome = v),
                    ),
                    if (!isIncome && totalAmount > 0) ...[
                      const Divider(height: 30),
                      const Text(
                        'Método de pago',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RadioListTile<String>(
                        title: Text(
                          'Todo en efectivo (\$${availableCash.toStringAsFixed(2)})',
                        ),
                        value: 'efectivo',
                        groupValue: paymentMode,
                        onChanged: (v) =>
                            setStateDialog(() => paymentMode = v!),
                      ),
                      RadioListTile<String>(
                        title: const Text('Seleccionar bancos'),
                        value: 'bancos',
                        groupValue: paymentMode,
                        onChanged: availableBanks.isNotEmpty
                            ? (v) => setStateDialog(() => paymentMode = v!)
                            : null,
                      ),
                      RadioListTile<String>(
                        title: const Text('Mixto'),
                        value: 'mixto',
                        groupValue: paymentMode,
                        onChanged:
                            (availableCash > 0 && availableBanks.isNotEmpty)
                            ? (v) => setStateDialog(() => paymentMode = v!)
                            : null,
                      ),
                      if (paymentMode == 'bancos' ||
                          paymentMode == 'mixto') ...[
                        const SizedBox(height: 10),
                        const Text('Distribución por banco:'),
                        ...availableBanks.asMap().entries.map((entry) {
                          final i = entry.key;
                          final bank = entry.value;
                          bankUsage[i] ??= 0.0; // Inicializar si no existe
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${bank.icon} ${bank.name} (\$${bank.balance.toStringAsFixed(2)})',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      hintText:
                                          bankUsage[i]?.toStringAsFixed(2) ??
                                          '0.00',
                                      prefixText: '\$ ',
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (v) {
                                      final val =
                                          double.tryParse(
                                            v.replaceAll(',', '.'),
                                          ) ??
                                          0.0;
                                      bankUsage[i] = val.clamp(
                                        0.0,
                                        bank.balance,
                                      );
                                      setStateDialog(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      if (paymentMode == 'mixto') ...[
                        const SizedBox(height: 10),
                        Text(
                          'Efectivo usado: \$${fromCash.toStringAsFixed(2)} (máx \$${availableCash.toStringAsFixed(2)})',
                        ),
                        Slider(
                          value: fromCash.clamp(
                            0.0,
                            math.min(
                              totalAmount -
                                  bankUsage.values.fold(0.0, (a, b) => a + b),
                              availableCash,
                            ),
                          ),
                          min: 0.0,
                          max: math.min(
                            totalAmount -
                                bankUsage.values.fold(0.0, (a, b) => a + b),
                            availableCash,
                          ),
                          divisions: 100,
                          label: fromCash.toStringAsFixed(
                            2,
                          ), // ← MUESTRA EL VALOR ACTUAL EN LA BURBUJA
                          onChanged: (v) => setStateDialog(() => fromCash = v),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (totalAmount <= 0) return;

                    double cashUse = paymentMode == 'efectivo'
                        ? totalAmount
                        : (paymentMode == 'mixto' ? fromCash : 0.0);

                    if (!isIncome &&
                        !provider.spend(totalAmount, cashUse, bankUsage)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fondos insuficientes')),
                      );
                      return;
                    }

                    if (isIncome) {
                      provider.cashBalance += totalAmount;
                      provider.settingsBox.put(
                        'cashBalance',
                        provider.cashBalance,
                      );
                    }

                    Map<String, double> paidWithBanksMap = {};
                    bankUsage.forEach((index, amount) {
                      if (amount > 0 && index < provider.bankAccounts.length) {
                        final bankName = provider.bankAccounts[index].name;
                        paidWithBanksMap[bankName] = amount;
                      }
                    });

                    double totalBankUse = bankUsage.values.fold(
                      0.0,
                      (a, b) => a + b,
                    );

                    provider.addTransactionWithDate(
                      totalAmount,
                      desc,
                      selectedCat,
                      isIncome,
                      selectedDate,
                      paidWithCash: cashUse,
                      paidWithBank: totalBankUse, // total para compatibilidad
                      paidWithBanks: paidWithBanksMap, // ← DETALLE POR BANCO
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isIncome ? 'Ingreso registrado' : 'Gasto registrado',
                        ),
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
