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
import '../models/transaction.dart';
import '../models/category.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        // STREAM BUILDER ADICIONAL para forzar rebuilds en release
        return StreamBuilder<bool>(
          stream: provider.refreshStream,
          initialData: true,
          builder: (context, snapshot) {
            // Este builder se ejecuta cada vez que el stream emite un valor
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.schedulePaymentNotifications();
              provider.loadBankAccounts();
              provider.updateTotals();
            });

            final available = provider.getAvailableToday();
            final dailyRef = provider.dailyIncome;
            final showAlert = available < dailyRef && available > 0 && dailyRef > 0;

            final expensesByCat = provider.getExpensesByCategoryLast30Days();
            final totalExpenses30Days = expensesByCat.values.fold(0.0, (a, b) => a + b);
            final dailyData = provider.getDailyExpensesLast7Days();

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
                    color: provider.lastPayDate != null ? Colors.orange : Colors.grey,
                    onPressed: provider.lastPayDate != null
                        ? () => _confirmCancelPayment(context, provider)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.payment),
                    tooltip: 'Marcar pago recibido',
                    color: provider.canMarkPayment() ? Colors.blue : Colors.grey,
                    onPressed: provider.canMarkPayment()
                        ? () => _confirmPayment(context, provider, provider.getExpectedPaycheck())
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.credit_card),
                    tooltip: 'Pagos fijos y tarjetas de crédito',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FixedPaymentsScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever),
                    tooltip: 'Ver transacciones eliminadas',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DeletedTransactionsScreen()),
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
                      MaterialPageRoute(builder: (_) => const QuincenalSummaryScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Exportar estado de cuenta',
                    onPressed: () => _showExportDialog(context, provider),
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
                                color: available >= dailyRef ? Colors.green : Colors.red,
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
                            _buildInfoRow('Saldo actual total', provider.getCurrentTotalBalance()),
                            _buildInfoRow('Ingreso diario (control)', provider.dailyIncome),
                            _buildInfoRow('Próximo pago esperado', provider.getExpectedPaycheck()),
                            if (provider.lastPayDate != null)
                              _buildInfoRow(
                                'Último pago recibido',
                                0,
                                date: provider.dateFormat.format(provider.lastPayDate!),
                              ),
                            _buildInfoRow('Ingresos extra hoy', provider.getTodayIncome(), positive: true),
                            _buildInfoRow('Gastado hoy', provider.getTodayExpenses(), positive: false),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Visualización de Gastos',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildChartSelector(provider),
                    const SizedBox(height: 20),
                    _buildSelectedChart(provider, expensesByCat, totalExpenses30Days, dailyData),
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
                              final uniqueKey = Key(
                                t.key?.toString() ?? '${t.date.millisecondsSinceEpoch}_${t.amount}_$i',
                              );
                              return Dismissible(
                                key: uniqueKey,
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white, size: 30),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('¿Eliminar transacción?'),
                                      content: Text(
                                        'Monto: \$${t.amount.toStringAsFixed(2)}\n'
                                        '${t.description}\n'
                                        'Métodos de pago:\n${_formatPaymentMethods(t)}',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) async {
                                  await provider.deleteTransactionImmediately(t, context);
                                },
                                child: InkWell(
                                  onTap: () => _showTransactionDetails(context, t, cat, provider),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          child: Text(cat.icon, style: const TextStyle(fontSize: 22)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.description,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                provider.dateFormat.format(t.date),
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                cat.name,
                                                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                              ),
                                              if (_formatPaymentMethods(t).isNotEmpty)
                                                Text(
                                                  _formatPaymentMethods(t),
                                                  style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${t.isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: t.isIncome ? Colors.green : Colors.red,
                                              ),
                                            ),
                                            if (!t.isIncome && t.paidWithBank > 0)
                                              Text(
                                                '${(t.paidWithBank / t.amount * 100).toStringAsFixed(0)}% banco',
                                                style: const TextStyle(fontSize: 9, color: Colors.blue),
                                              ),
                                          ],
                                        ),
                                      ],
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
      },
    );
  }

  void _showExportDialog(BuildContext context, FinanceProvider provider) {
    List<Map<String, dynamic>> monthOptions = _generateMonthListFrom2026();
    String selectedMonthKey = monthOptions.isNotEmpty ? monthOptions.first['key'] : '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Exportar Estado de Cuenta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Seleccionar mes a exportar:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedMonthKey,
                      items: monthOptions.map((month) {
                        return DropdownMenuItem<String>(
                          value: month['key'],
                          child: Text(month['display']),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setStateDialog(() => selectedMonthKey = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Formato de exportación:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Formato PDF',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(Icons.check_circle, color: Colors.green[700]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'El PDF incluirá:\n'
                        '• Resumen mensual\n'
                        '• Detalle de transacciones\n'
                        '• Análisis por categoría\n'
                        '• Totales de ingresos y gastos\n'
                        '• Saldo inicial y final',
                        style: TextStyle(fontSize: 12, color: Colors.blue[800]),
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Generar PDF'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final selectedMonth = monthOptions.firstWhere(
                      (m) => m['key'] == selectedMonthKey,
                      orElse: () => monthOptions.first,
                    );
                    await ExportService.exportMonthToPDF(
                      context,
                      provider,
                      selectedMonth['date'],
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _generateMonthListFrom2026() {
    final List<Map<String, dynamic>> months = [];
    final formatter = DateFormat('MMMM yyyy', 'es_MX');
    final now = DateTime.now();
    DateTime currentMonth = DateTime(2026, 1, 1);

    while (currentMonth.isBefore(now) ||
        (currentMonth.year == now.year && currentMonth.month <= now.month)) {
      months.add({
        'date': currentMonth,
        'key': '${currentMonth.year}-${currentMonth.month}',
        'display': formatter.format(currentMonth),
      });

      if (currentMonth.month == 12) {
        currentMonth = DateTime(currentMonth.year + 1, 1, 1);
      } else {
        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }
    }

    months.sort((a, b) => b['date'].compareTo(a['date']));
    return months;
  }

  Widget _buildChartSelector(FinanceProvider provider) {
    return SegmentedButton<ChartType>(
      segments: const [
        ButtonSegment<ChartType>(value: ChartType.pie, label: Text('Pastel'), icon: Icon(Icons.pie_chart)),
        ButtonSegment<ChartType>(value: ChartType.bar, label: Text('Barras'), icon: Icon(Icons.bar_chart)),
        ButtonSegment<ChartType>(value: ChartType.line, label: Text('Tendencia'), icon: Icon(Icons.show_chart)),
      ],
      selected: {provider.selectedChartType},
      onSelectionChanged: (Set<ChartType> newSelection) {
        provider.setChartType(newSelection.first);
      },
    );
  }

  Widget _buildSelectedChart(
    FinanceProvider provider,
    Map<String, double> expensesByCat,
    double totalExpenses30Days,
    List<Map<String, dynamic>> dailyData,
  ) {
    switch (provider.selectedChartType) {
      case ChartType.bar:
        return _buildBarChart(expensesByCat, totalExpenses30Days);
      case ChartType.line:
        return _buildEnhancedLineChart(dailyData);
      case ChartType.pie:
      default:
        return _buildEnhancedPieChart(expensesByCat, totalExpenses30Days);
    }
  }

  Widget _buildEnhancedPieChart(Map<String, double> expensesByCat, double total) {
    if (total == 0) {
      return const Center(
        child: Text(
          'Aún no hay gastos registrados en los últimos 30 días',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final sortedEntries = expensesByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 400,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: sortedEntries.take(8).map((e) {
                  final index = sortedEntries.indexOf(e);
                  final percentage = total > 0 ? (e.value / total * 100) : 0;
                  return PieChartSectionData(
                    value: e.value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: _getChartColor(index),
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getChartColor(index),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                    badgePositionPercentageOffset: 0.95,
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ListView(
                shrinkWrap: true,
                children: sortedEntries.take(8).map((e) {
                  final index = sortedEntries.indexOf(e);
                  final percentage = total > 0 ? (e.value / total * 100) : 0;
                  return ListTile(
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getChartColor(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      e.key,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '\$${e.value.toStringAsFixed(2)}\n(${percentage.toStringAsFixed(1)}%)',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> expensesByCat, double total) {
    if (total == 0) {
      return const Center(
        child: Text(
          'Aún no hay gastos registrados en los últimos 30 días',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final sortedEntries = expensesByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final limitedEntries = sortedEntries.take(10).toList();

    return SizedBox(
      height: 400,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: limitedEntries.isNotEmpty ? limitedEntries.first.value * 1.1 : 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final category = limitedEntries[groupIndex].key;
                final value = limitedEntries[groupIndex].value;
                final percentage = (value / total * 100).toStringAsFixed(1);
                return BarTooltipItem(
                  '$category\n\$${value.toStringAsFixed(2)} ($percentage%)',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < limitedEntries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        limitedEntries[index].key,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          barGroups: limitedEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: _getChartColor(index),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnhancedLineChart(List<Map<String, dynamic>> dailyData) {
    if (dailyData.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos de gastos diarios',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final spots = dailyData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value['amount']);
    }).toList();

    final maxAmount = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final avgAmount = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;

    return SizedBox(
      height: 320,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < dailyData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dailyData[value.toInt()]['day'],
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 50),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.red,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.3),
                    Colors.red.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            LineChartBarData(
              spots: [
                FlSpot(0, avgAmount),
                FlSpot(dailyData.length.toDouble() - 1, avgAmount),
              ],
              isCurved: false,
              color: Colors.blue.withOpacity(0.5),
              barWidth: 2,
              dashArray: const [5, 5],
              dotData: const FlDotData(show: false),
            ),
          ],
          minY: 0,
          maxY: maxAmount * 1.2,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final index = touchedSpot.spotIndex;
                  return LineTooltipItem(
                    '${dailyData[index]['day']}\n'
                    'Gasto: \$${touchedSpot.y.toStringAsFixed(2)}\n'
                    'Promedio: \$${avgAmount.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.black),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
      Colors.cyanAccent,
      Colors.limeAccent,
    ];
    return colors[index % colors.length];
  }

  String _formatPaymentMethods(Transaction t) {
    final methods = <String>[];
    if (t.paidWithCash > 0) {
      methods.add('Efectivo: \$${t.paidWithCash.toStringAsFixed(2)}');
    }
    if (t.paidWithBank > 0) {
      methods.add('Banco: \$${t.paidWithBank.toStringAsFixed(2)}');
    }
    if (t.paidWithBanks.isNotEmpty) {
      t.paidWithBanks.forEach((bankName, amount) {
        methods.add('$bankName: \$${amount.toStringAsFixed(2)}');
      });
    }
    return methods.join(' | ');
  }

  void _showTransactionDetails(
    BuildContext context,
    Transaction t,
    Category cat,
    FinanceProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalles de la Transacción'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Text(cat.icon, style: const TextStyle(fontSize: 36)),
                title: Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(t.description),
              ),
              const Divider(),
              _buildDetailRow('Fecha', provider.dateFormat.format(t.date)),
              _buildDetailRow(
                'Monto',
                '\$${t.amount.toStringAsFixed(2)}',
                color: t.isIncome ? Colors.green : Colors.red,
              ),
              _buildDetailRow('Tipo', t.isIncome ? 'Ingreso' : 'Gasto'),
              if (!t.isIncome) ...[
                const SizedBox(height: 16),
                const Text(
                  'Métodos de Pago:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (t.paidWithCash > 0)
                  _buildDetailRow(
                    'Efectivo',
                    '\$${t.paidWithCash.toStringAsFixed(2)}',
                  ),
                if (t.paidWithBank > 0)
                  _buildDetailRow(
                    'Total Bancos',
                    '\$${t.paidWithBank.toStringAsFixed(2)}',
                  ),
                if (t.paidWithBanks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Distribución por banco:',
                    style: TextStyle(fontSize: 12),
                  ),
                  ...t.paidWithBanks.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        '${entry.key}: \$${entry.value.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
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
      text: provider.hasSetCash
          ? provider.cashBalance.toStringAsFixed(2)
          : '0.00',
    );

    final bankControllers = provider.bankAccounts.map((account) {
      return TextEditingController(text: account.balance.toStringAsFixed(2));
    }).toList();

    final newBankNameController = TextEditingController();
    final newBankBalanceController = TextEditingController(text: '0.00');

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
                        hintText: 'Ej. 1000.00 (0 si vacío)',
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
                            hintText: 'Ej. 1500.00 (0 si vacío)',
                          ),
                        ),
                      );
                    }).toList(),
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
                        hintText: '0.00 si vacío',
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
                    // VALIDACIÓN: Efectivo
                    final cashText = cashController.text
                        .replaceAll(',', '.')
                        .trim();
                    final cash = double.tryParse(cashText) ?? 0.0;
                    if (cash < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El efectivo no puede ser negativo'),
                        ),
                      );
                      return;
                    }
                    
                    provider.updateCashBalance(cash);

                    // VALIDACIÓN: Bancos existentes
                    for (var i = 0; i < provider.bankAccounts.length; i++) {
                      final text = bankControllers[i].text
                          .replaceAll(',', '.')
                          .trim();
                      final value = double.tryParse(text) ?? 0.0;
                      if (value < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('El saldo de ${provider.bankAccounts[i].name} no puede ser negativo'),
                          ),
                        );
                        return;
                      }
                      
                      final account = provider.bankAccounts[i];
                      account.balance = value;
                      provider.updateBankAccount(account.key!, account);
                    }

                    // VALIDACIÓN: Nueva banco
                    final newName = newBankNameController.text.trim();
                    final newBalanceText = newBankBalanceController.text
                        .replaceAll(',', '.')
                        .trim();
                    if (newName.isNotEmpty) {
                      final newBalance = double.tryParse(newBalanceText) ?? 0.0;
                      if (newBalance < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El saldo inicial no puede ser negativo'),
                          ),
                        );
                        return;
                      }
                      
                      provider.addBankAccount(
                        BankAccount(name: newName, balance: newBalance),
                      );
                    }

                    Navigator.pop(ctx);
                    
                    // Forzar refresh inmediato
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      provider.updateTotals();
                    });
                    
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
              
              // Forzar refresh
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.updateTotals();
              });
              
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
              
              // Forzar refresh
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.updateTotals();
              });
              
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
    Map<int, double> bankUsage = {};
    String desc = '';
    int selectedCat = 3;
    bool isIncome = false;
    String paymentMode = 'efectivo';
    DateTime selectedDate = DateTime.now();

    final descController = TextEditingController();
    final amountController = TextEditingController();

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
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto total *',
                        hintText: 'Ej. 150.50',
                      ),
                      onChanged: (v) {
                        totalAmount =
                            double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        hintText:
                            '¿En qué gastaste? o ¿De dónde es el ingreso?',
                        errorText: 'La descripción es obligatoria',
                      ),
                      onChanged: (v) => desc = v,
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<int>(
                      isExpanded: true,
                      value: selectedCat,
                      hint: const Text('Categoría *'),
                      items: provider.categories.asMap().entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text('${e.value.icon} ${e.value.name}'),
                        );
                      }).toList(),
                      onChanged: (v) => setStateDialog(() => selectedCat = v!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Fecha *'),
                      subtitle: Text(provider.dateFormat.format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.green,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedDate = picked);
                        }
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
                          bankUsage[i] ??= 0.0;
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
                        }).toList(),
                      ],
                      if (paymentMode == 'mixto') ...[
                        const SizedBox(height: 10),
                        Builder(
                          builder: (context) {
                            double totalBankUse = bankUsage.values.fold(
                              0.0,
                              (a, b) => a + b,
                            );
                            double remainingForCash = math.max(
                              0.0,
                              totalAmount - totalBankUse,
                            );
                            double maxCash = math.min(
                              remainingForCash,
                              availableCash,
                            );
                            if (fromCash > maxCash) {
                              fromCash = maxCash;
                            }
                            maxCash = math.max(0.0, maxCash);
                            return Column(
                              children: [
                                Text(
                                  'Efectivo usado: \$${fromCash.toStringAsFixed(2)} (máx \$${maxCash.toStringAsFixed(2)})',
                                ),
                                if (maxCash > 0)
                                  Slider(
                                    value: fromCash,
                                    min: 0.0,
                                    max: maxCash,
                                    divisions: math.max(
                                      1,
                                      (maxCash * 100).round(),
                                    ),
                                    label: fromCash.toStringAsFixed(2),
                                    onChanged: (v) => setStateDialog(() {
                                      fromCash = double.parse(
                                        v.toStringAsFixed(2),
                                      );
                                    }),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'No hay efectivo disponible para esta distribución',
                                      style: TextStyle(color: Colors.red[600]),
                                    ),
                                  ),
                              ],
                            );
                          },
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
                  onPressed: () async {
                    if (totalAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ingresa un monto válido'),
                        ),
                      );
                      return;
                    }

                    if (desc.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('La descripción es obligatoria'),
                        ),
                      );
                      descController.clear();
                      return;
                    }

                    if (!isIncome) {
                      double cashUse = paymentMode == 'efectivo'
                          ? totalAmount
                          : (paymentMode == 'mixto' ? fromCash : 0.0);

                      double totalBankUse = bankUsage.values.fold(
                        0.0,
                        (a, b) => a + b,
                      );

                      double totalDistributed = cashUse + totalBankUse;
                      if ((totalDistributed - totalAmount).abs() > 0.01) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La distribución no coincide con el total',
                            ),
                          ),
                        );
                        return;
                      }

                      if (cashUse > provider.cashBalance + 0.01) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Fondos insuficientes en efectivo. Disponible: \$${provider.cashBalance.toStringAsFixed(2)}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      bool banksOk = true;
                      bankUsage.forEach((index, amount) {
                        if (amount > 0 &&
                            index < provider.bankAccounts.length) {
                          final bank = provider.bankAccounts[index];
                          if (amount > bank.balance + 0.01) {
                            banksOk = false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Fondos insuficientes en ${bank.name}. Disponible: \$${bank.balance.toStringAsFixed(2)}',
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      });

                      if (!banksOk) return;

                      if (!provider.spend(totalAmount, cashUse, bankUsage)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Fondos insuficientes'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                    } else {
                      provider.cashBalance += totalAmount;
                      provider.settingsBox.put(
                        'cashBalance',
                        provider.cashBalance,
                      );
                      provider.flushSettings();
                    }

                    Map<String, double> paidWithBanksMap = {};
                    bankUsage.forEach((index, amount) {
                      if (amount > 0 && index < provider.bankAccounts.length) {
                        final bankName = provider.bankAccounts[index].name;
                        paidWithBanksMap[bankName] = amount;
                      }
                    });

                    provider.addTransactionWithDate(
                      totalAmount,
                      desc,
                      selectedCat,
                      isIncome,
                      selectedDate,
                      paidWithCash: paymentMode == 'efectivo'
                          ? totalAmount
                          : (paymentMode == 'mixto' ? fromCash : 0.0),
                      paidWithBank: bankUsage.values.fold(0.0, (a, b) => a + b),
                      paidWithBanks: paidWithBanksMap,
                    );

                    Navigator.of(context).pop();
                    
                    // Forzar refresh
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      provider.updateTotals();
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isIncome ? 'Ingreso registrado' : 'Gasto registrado',
                        ),
                        duration: const Duration(seconds: 2),
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