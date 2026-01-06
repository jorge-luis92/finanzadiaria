import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/manual_fixed_expense.dart';

class ManualFixedExpensesScreen extends StatelessWidget {
  const ManualFixedExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gastos Fijos Manuales'),
            backgroundColor: Colors.red[100],
          ),
          body: provider.manualFixedExpenses.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No hay gastos fijos manuales configurados.\n\nToca el botón + para agregar gastos recurrentes como:\n• Renta / Casa\n• Comida\n• Gasolina\n• Transporte\n• Etc.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.manualFixedExpenses.length,
                  itemBuilder: (context, i) {
                    final expense = provider.manualFixedExpenses[i];
                    return Card(
                      child: ListTile(
                        leading: Text(expense.icon, style: const TextStyle(fontSize: 36)),
                        title: Text(expense.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, provider, expense.key),
                            ),
                          ],
                        ),
                        onTap: () => _editExpense(context, provider, expense),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () => _editExpense(context, provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, FinanceProvider provider, dynamic key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar gasto fijo?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteManualFixedExpense(key);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gasto eliminado')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _editExpense(BuildContext context, FinanceProvider provider, [ManualFixedExpense? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(text: existing?.amount.toStringAsFixed(2) ?? '');
    String selectedIcon = existing?.icon ?? '🏠';

    final icons = ['🏠', '🍽️', '⛽', '🚕', '💡', '📱', '🛒', '🏥', '🎓', '🛍️', '💊', '🧹', '📚'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(existing == null ? 'Nuevo gasto fijo' : 'Editar gasto fijo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del gasto',
                        hintText: 'Ej. Renta, Comida, Gasolina',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto por período',
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Icono', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: icons.map((icon) {
                        return GestureDetector(
                          onTap: () => setStateDialog(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selectedIcon == icon ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selectedIcon == icon ? Colors.red : Colors.transparent, width: 2),
                            ),
                            child: Text(icon, style: const TextStyle(fontSize: 32)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final amountText = amountController.text.replaceAll(',', '.');
                    final amount = double.tryParse(amountText) ?? 0.0;

                    if (name.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Completa nombre y monto válido')),
                      );
                      return;
                    }

                    final expense = ManualFixedExpense(
                      name: name,
                      amount: amount,
                      icon: selectedIcon,
                    );

                    if (existing == null) {
                      provider.addManualFixedExpense(expense);
                    } else {
                      provider.updateManualFixedExpense(existing.key, expense);
                    }

                    Navigator.pop(ctx);
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