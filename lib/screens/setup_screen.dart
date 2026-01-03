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
  final _dailyIncomeController = TextEditingController();
  final _daysWorkedController = TextEditingController();
  String _selectedFreq = 'mensual';

  final Map<String, String> freqNames = {
    'semanal': 'Semanal (7 días)',
    'catorcena': 'Catorcenal (14 días)',
    'quincenal': 'Quincenal (15/16 días)',
    'mensual': 'Mensual (30 días)',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateDefaultDays());
  }

  void _updateDefaultDays() {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    _daysWorkedController.text = provider.getDefaultDaysForPeriod().toString();
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
              const Text('¡Bienvenido a FinanzaDiaria!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              TextField(
                controller: _dailyIncomeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Ingreso por día trabajado', prefixText: '\$ ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _daysWorkedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Días trabajados', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedFreq,
                decoration: const InputDecoration(labelText: 'Frecuencia', border: OutlineInputBorder()),
                items: freqNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedFreq = v!;
                    final provider = Provider.of<FinanceProvider>(context, listen: false);
                    _daysWorkedController.text = provider.getDefaultDaysForPeriod().toString();
                  });
                },
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  final daily = double.tryParse(_dailyIncomeController.text.replaceAll(',', '.')) ?? 0;
                  final days = int.tryParse(_daysWorkedController.text) ?? 0;
                  if (daily > 0 && days > 0) {
                    Provider.of<FinanceProvider>(context, listen: false).saveIncomeConfig(daily, _selectedFreq, days);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valores inválidos')));
                  }
                },
                child: const Text('Guardar y Comenzar', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}