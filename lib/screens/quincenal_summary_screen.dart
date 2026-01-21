import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import 'money_destinations_screen.dart';
import 'manual_fixed_expenses_screen.dart';
import 'bank_accounts_screen.dart';
import 'savings_goal_screen.dart';

class QuincenalSummaryScreen extends StatelessWidget {
  const QuincenalSummaryScreen({super.key});

  String _getTitle(String frequency) {
    switch (frequency) {
      case 'semanal':
        return 'Resumen Semanal';
      case 'catorcena':
        return 'Resumen Catorcenal';
      case 'quincenal':
        return 'Resumen Quincenal';
      case 'mensual':
        return 'Resumen Mensual';
      default:
        return 'Resumen del Período';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        // Usar el StreamBuilder para forzar actualizaciones en release
        return StreamBuilder<bool>(
          stream: provider.refreshStream,
          initialData: true,
          builder: (context, snapshot) {
            // Cálculos actualizados
            final baseDiaria = provider.dailyIncome;
            final diasTrabajados = provider.daysWorkedPerPeriod.toDouble();
            final subtotalBruto = baseDiaria * diasTrabajados;
            final comisiones = 0.0;
            final deducciones = provider.deductions;
            final ingresoNeto = subtotalBruto + comisiones - deducciones;

            // Distribución (INGRESO)
            final totalDistribuido = provider.moneyDestinations.fold(
              0.0,
              (sum, d) => sum + d.amount,
            );

            // Saldos actuales
            final totalSaldosActuales = provider.getCurrentTotalBalance();

            // Gastos fijos planeados
            double gastosFijosPlaneados = provider.deductions;
            for (var p in provider.fixedPayments) {
              gastosFijosPlaneados += p.minimumPayment;
            }
            for (var e in provider.manualFixedExpenses) {
              gastosFijosPlaneados += e.amount;
            }

            // Gastos variables reales (filtrado por período)
            double gastosVariablesReales = provider.getVariableExpensesForCurrentPeriod();

            // Resultado final
            final totalIngresos =
                ingresoNeto + totalDistribuido + totalSaldosActuales;
            final totalGastos = gastosFijosPlaneados + gastosVariablesReales;
            final gastosFijosP = gastosFijosPlaneados;
            final gastosReales = gastosVariablesReales;
            final restante = totalIngresos - totalGastos;
            final paraGastar = (restante - provider.savingsGoal) > 0
                ? (restante - provider.savingsGoal)
                : 0.0;
            final enNegativo = restante < 0 ? restante.abs() : 0.0;

            return Scaffold(
              appBar: AppBar(
                title: Text(_getTitle(provider.payFrequency)),
                backgroundColor: Colors.indigo[100],
                actions: [
                  // Botón de refresh manual
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      provider.forceFullRefresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Datos actualizados'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Actualizar datos',
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  provider.forceFullRefresh();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INGRESOS
                      const Text(
                        'Ingresos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        'Base diaria',
                        '\$${baseDiaria.toStringAsFixed(2)}',
                      ),
                      _buildRow(
                        'Días trabajados',
                        diasTrabajados.toStringAsFixed(0),
                      ),
                      _buildRow(
                        'Subtotal bruto',
                        '\$${subtotalBruto.toStringAsFixed(2)}',
                      ),
                      _buildRow('Comisiones', '\$${comisiones.toStringAsFixed(2)}'),
                      _buildEditableRow(
                        label: 'Deducciones',
                        value: '-\$${deducciones.toStringAsFixed(2)}',
                        color: Colors.red,
                        onTap: () => _editDeductions(context, provider),
                      ),
                      const Divider(height: 30, thickness: 2),
                      _buildRow(
                        'Ingreso neto',
                        '\$${ingresoNeto.toStringAsFixed(2)}',
                        bold: true,
                        color: Colors.green,
                      ),

                      const SizedBox(height: 30),

                      // DISTRIBUCIÓN DE DINERO
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Distribución de dinero',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MoneyDestinationsScreen(),
                              ),
                            ),
                            tooltip: 'Agregar destino',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.moneyDestinations.isEmpty)
                        const Text(
                          'No has configurado destinos.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...provider.moneyDestinations.map(
                          (d) => _buildRow(
                            '${d.icon} ${d.name}',
                            '\$${d.amount.toStringAsFixed(2)}',
                          ),
                        ),
                      const Divider(height: 30, thickness: 2),
                      _buildRow(
                        'Total distribución',
                        '\$${totalDistribuido.toStringAsFixed(2)}',
                        bold: true,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 30),

                      // SALDOS ACTUALES
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Saldos actuales',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BankAccountsScreen(),
                              ),
                            ),
                            tooltip: 'Agregar cuenta',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        '💵 Efectivo en mano',
                        '\$${provider.cashBalance.toStringAsFixed(2)}',
                      ),
                      if (provider.bankAccounts.isEmpty)
                        const Text(
                          'No has configurado cuentas bancarias',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...provider.bankAccounts.map(
                          (b) => _buildRow(
                            '${b.icon} ${b.name}',
                            '\$${b.balance.toStringAsFixed(2)}',
                          ),
                        ),
                      const Divider(height: 30, thickness: 2),
                      _buildRow(
                        'Total saldos actuales',
                        '\$${totalSaldosActuales.toStringAsFixed(2)}',
                        bold: true,
                        color: Colors.indigo,
                      ),

                      const SizedBox(height: 30),

                      // GASTOS FIJOS PLANEADOS
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Gastos fijos planeados',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManualFixedExpensesScreen(),
                              ),
                            ),
                            tooltip: 'Agregar gasto fijo',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...provider.fixedPayments.map(
                        (p) => _buildRow(
                          '${p.icon} ${p.name}',
                          '\$${p.minimumPayment.toStringAsFixed(2)}',
                        ),
                      ),
                      ...provider.manualFixedExpenses.map(
                        (e) => _buildRow(
                          '${e.icon} ${e.name}',
                          '\$${e.amount.toStringAsFixed(2)}',
                        ),
                      ),
                      const Divider(height: 30, thickness: 2),
                      _buildRow(
                        'Total fijos planeados',
                        '\$${gastosFijosPlaneados.toStringAsFixed(2)}',
                        bold: true,
                        color: Colors.orange,
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Gastos variables reales (registrados)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        'Total registrados',
                        '\$${gastosVariablesReales.toStringAsFixed(2)}',
                        bold: true,
                        color: Colors.red,
                      ),
                      if (gastosVariablesReales > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Período: ${provider.dateFormat.format(provider.getStartOfPeriod())} - ${provider.dateFormat.format(DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // RESULTADO FINAL
                      Card(
                        elevation: 8,
                        color: restante >= 0
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text(
                                'Resultado Final',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildRow(
                                'Total ingresos + distribución + saldos',
                                '\$${totalIngresos.toStringAsFixed(2)}',
                                bold: true,
                                color: Colors.green,
                              ),
                              _buildRow(
                                'Total gastos (planeados - fijos)',
                                '\$${gastosFijosP.toStringAsFixed(2)}',
                                bold: true,
                                color: Colors.red,
                              ),
                               _buildRow(
                                'Total gastos (ordinarios - reales)',
                                '\$${gastosReales.toStringAsFixed(2)}',
                                bold: true,
                                color: Colors.red,
                              ),
                              const Divider(),
                              _buildRow(
                                'Meta de ahorro',
                                '\$${provider.savingsGoal.toStringAsFixed(2)} (${provider.saveInCash ? 'Efectivo' : 'Banca'})',
                                bold: true,
                              ),
                              _buildRow(
                                'Quedó para gastar libre',
                                '\$${paraGastar.toStringAsFixed(2)}',
                                bold: true,
                                color: Colors.green,
                              ),
                              if (enNegativo > 0)
                                _buildRow(
                                  'Déficit',
                                  '-\$${enNegativo.toStringAsFixed(2)}',
                                  bold: true,
                                  color: Colors.red,
                                ),
                              const SizedBox(height: 20),
                              Text(
                                restante >= 0
                                    ? '¡Excelente! Tienes dinero disponible.'
                                    : 'Revisar gastos: quedaste corto.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: restante >= 0 ? Colors.green : Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // BOTONES DE CONFIGURACIÓN
                      Center(
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.account_balance_wallet),
                              label: const Text('Configurar Destinos de Dinero'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MoneyDestinationsScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.account_balance),
                              label: const Text('Configurar Cuentas Bancarias'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BankAccountsScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Editar Gastos Fijos Planeados'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManualFixedExpensesScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.savings),
                              label: const Text('Editar Meta de Ahorro'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SavingsGoalScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow({
    required String label,
    required String value,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      color: color ?? Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editDeductions(BuildContext context, FinanceProvider provider) {
    final controller = TextEditingController(
      text: provider.deductions.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar deducciones'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto de deducciones',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final value =
                  double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.00;
              provider.deductions = value;
              Navigator.pop(ctx);
              provider.forceFullRefresh(); // Forzar refresh completo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deducciones actualizadas')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}