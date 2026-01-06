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

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    _goalController.text = provider.savingsGoal.toStringAsFixed(2);
    _saveInCash = provider.saveInCash;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meta de Ahorro')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _goalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Meta de ahorro por quincena',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SwitchListTile(
              title: const Text('Ahorrar en efectivo'),
              subtitle: Text(_saveInCash ? 'Se suma al saldo de efectivo' : 'Se suma al saldo de banca'),
              value: _saveInCash,
              onChanged: (v) => setState(() => _saveInCash = v),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              onPressed: () {
                final goal = double.tryParse(_goalController.text.replaceAll(',', '.')) ?? 0.0;
                Provider.of<FinanceProvider>(context, listen: false).setSavingsGoal(goal, _saveInCash);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta de ahorro guardada')));
              },
              child: const Text('Guardar Meta', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}