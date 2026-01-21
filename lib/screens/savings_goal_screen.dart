import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({super.key});

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen> {
  final _goalController = TextEditingController();
  bool _saveInCash = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    _goalController.text = provider.savingsGoal.toStringAsFixed(2);
    _saveInCash = provider.saveInCash;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        return StreamBuilder<bool>(
          stream: provider.refreshStream,
          initialData: true,
          builder: (context, snapshot) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Meta de Ahorro'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      await _loadCurrentSettings();
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuración actualizada'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '¿Qué es la meta de ahorro?',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Es la cantidad que quieres ahorrar cada período (quincena, mes, etc.) después de cubrir todos tus gastos.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Ejemplo: Si tu ingreso neto es \$10,000 y tus gastos son \$8,000, puedes ahorrar \$2,000.',
                                          style: TextStyle(color: Colors.blue[800]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _goalController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Meta de ahorro por período',
                              prefixText: '\$ ',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _goalController.clear();
                                  setState(() {});
                                },
                              ),
                              hintText: 'Ej. 2000.00',
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getPeriodText(provider.payFrequency),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SwitchListTile(
                              title: const Text(
                                'Ahorrar en efectivo',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                _saveInCash
                                    ? 'El ahorro se sumará a tu saldo en efectivo'
                                    : 'El ahorro se sumará a tu saldo en banca',
                              ),
                              value: _saveInCash,
                              onChanged: (value) {
                                setState(() => _saveInCash = value);
                              },
                              secondary: Icon(
                                _saveInCash ? Icons.wallet : Icons.account_balance,
                                color: _saveInCash ? Colors.green : Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                _saveInCash ? Icons.check_circle : Icons.account_balance,
                                color: _saveInCash ? Colors.green : Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _saveInCash
                                      ? 'Recomendado para ahorros pequeños y acceso inmediato'
                                      : 'Recomendado para ahorros mayores y mejor control',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.green[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                final goal = double.tryParse(
                                      _goalController.text.replaceAll(',', '.'),
                                    ) ??
                                    0.0;
                                
                                if (goal < 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('La meta no puede ser negativa'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                provider.setSavingsGoal(goal, _saveInCash);
                                provider.forceFullRefresh();
                                
                                Navigator.pop(context);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      goal > 0
                                          ? 'Meta de ahorro guardada: \$${goal.toStringAsFixed(2)}'
                                          : 'Meta de ahorro desactivada',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Text(
                                'Guardar Meta',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                _goalController.text = '0.00';
                                _saveInCash = true;
                                provider.setSavingsGoal(0.0, true);
                                provider.forceFullRefresh();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Meta de ahorro desactivada'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              child: const Text(
                                'Desactivar meta de ahorro',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  String _getPeriodText(String frequency) {
    switch (frequency) {
      case 'semanal':
        return 'Esta meta se aplicará cada semana';
      case 'catorcena':
        return 'Esta meta se aplicará cada catorcena (14 días)';
      case 'quincenal':
        return 'Esta meta se aplicará cada quincena';
      case 'mensual':
        return 'Esta meta se aplicará cada mes';
      default:
        return 'Esta meta se aplicará cada período';
    }
  }
}