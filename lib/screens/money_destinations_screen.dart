import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/money_destination.dart';

class MoneyDestinationsScreen extends StatelessWidget {
  const MoneyDestinationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ingresos extras de Dinero')),
          body: provider.moneyDestinations.isEmpty
              ? const Center(child: Text('Agrega personas, cuentas o ahorros'))
              : ListView.builder(
                  itemCount: provider.moneyDestinations.length,
                  itemBuilder: (context, i) {
                    final dest = provider.moneyDestinations[i];
                    return ListTile(
                      leading: Text(
                        dest.icon,
                        style: const TextStyle(fontSize: 36),
                      ),
                      title: Text(dest.name),
                      trailing: Text('\$${dest.amount.toStringAsFixed(2)}'),
                      onTap: () => _editDestination(context, provider, dest),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _editDestination(context, provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _editDestination(
    BuildContext context,
    FinanceProvider provider, [
    MoneyDestination? existing,
  ]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
      text: existing?.amount.toStringAsFixed(2) ?? '',
    );
    String icon = existing?.icon ?? '👤';
    final icons = ['👤', '🏦', '💰', '🏠', '💳', '🚗', '❤️', '🎁'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(existing == null ? 'Nuevo destino' : 'Editar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre (ej. Tanda)',
                ),
              ),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto fijo por período',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                children: icons
                    .map(
                      (ic) => GestureDetector(
                        onTap: () => setStateDialog(() => icon = ic),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: icon == ic ? Colors.blue : Colors.grey,
                            ),
                          ),
                          child: Text(ic, style: const TextStyle(fontSize: 32)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount =
                    double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                if (nameCtrl.text.isEmpty || amount <= 0) return;
                final dest = MoneyDestination(
                  name: nameCtrl.text.trim(),
                  amount: amount,
                  icon: icon,
                );
                if (existing == null) {
                  provider.addMoneyDestination(dest);
                } else {
                  provider.updateMoneyDestination(existing.key, dest);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
