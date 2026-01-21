import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String _selectedFreq = 'quincenal';
  final _dailyIncomeController = TextEditingController();
  late TextEditingController _daysWorkedController;
  int _daysWorked = 15;

  final Map<String, String> freqNames = {
    'semanal': 'Semanal',
    'catorcena': 'Catorcenal (14 días)',
    'quincenal': 'Quincenal',
    'mensual': 'Mensual',
  };

  @override
  void initState() {
    super.initState();
    _daysWorked = _calculateDaysForFreq(_selectedFreq);
    _daysWorkedController = TextEditingController(text: _daysWorked.toString());
  }

  @override
  void dispose() {
    _daysWorkedController.dispose();
    super.dispose();
  }

  int _calculateDaysForFreq(String freq) {
    final now = DateTime.now();
    switch (freq) {
      case 'semanal':
        return 7;
      case 'catorcena':
        return 14;
      case 'quincenal':
        if (now.day <= 15) {
          return 15;
        } else {
          final lastDay = DateTime(now.year, now.month + 1, 0).day;
          return lastDay - 15;
        }
      case 'mensual':
        return DateTime(now.year, now.month + 1, 0).day;
      default:
        return 15;
    }
  }

  void _onFrequencyChanged(String? newFreq) {
    if (newFreq == null) return;
    setState(() {
      _selectedFreq = newFreq;
      _daysWorked = _calculateDaysForFreq(newFreq);
      _daysWorkedController.text = _daysWorked.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración Inicial')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                '¡Bienvenido a FinanzaDiaria!\nConfigura tu ingreso',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              DropdownButtonFormField<String>(
                value: _selectedFreq,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia de pago',
                  border: OutlineInputBorder(),
                ),
                items: freqNames.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: _onFrequencyChanged,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _daysWorkedController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Días trabajados este período',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar días trabajados (si trabajaste menos)',
                    onPressed: () async {
                      final controller = TextEditingController(text: _daysWorked.toString());

                      final newDays = await showDialog<int>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Editar días trabajados'),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(hintText: 'Actual: $_daysWorked'),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                            ElevatedButton(
                              onPressed: () {
                                final val = int.tryParse(controller.text);
                                Navigator.pop(ctx, val != null && val > 0 ? val : _daysWorked);
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      );

                      if (newDays != null) {
                        setState(() {
                          _daysWorked = newDays;
                          _daysWorkedController.text = _daysWorked.toString();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _dailyIncomeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Ingreso por día trabajado',
                  hintText: 'Ejemplo: 500',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 50),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  final daily = double.tryParse(_dailyIncomeController.text.replaceAll(',', '.')) ?? 0;
                  if (daily > 0) {
                    Provider.of<FinanceProvider>(context, listen: false)
                        .saveIncomeConfig(daily, _selectedFreq, _daysWorked);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingresa un ingreso válido')),
                    );
                  }
                },
                child: const Text('Guardar y Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}