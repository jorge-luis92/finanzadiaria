// fixed_payments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/fixed_payment.dart';

class FixedPaymentsScreen extends StatelessWidget {
  const FixedPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pagos Fijos y Tarjetas'),
            backgroundColor: Colors.deepPurple[100],
          ),
          body: provider.fixedPayments.isEmpty
              ? const Center(
                  child: Text(
                    'Sin pagos fijos.\nToca + para agregar',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: provider.fixedPayments.length,
                  itemBuilder: (context, i) {
                    final p = provider.fixedPayments[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(p.icon)),
                      title: Text(p.name),
                      subtitle: Text(
                        'Corte: día ${p.cutDay} | Vencimiento: día ${p.dueDay} | Total: \$${p.totalAmount.toStringAsFixed(2)} | Mínimo: \$${p.minimumPayment.toStringAsFixed(2)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(context, provider, p),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => _showEditDialog(context, provider),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, FinanceProvider provider, [FixedPayment? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final totalCtrl = TextEditingController(text: existing?.totalAmount.toStringAsFixed(2) ?? '');
    final minCtrl = TextEditingController(text: existing?.minimumPayment.toStringAsFixed(2) ?? '');
    int cut = existing?.cutDay ?? 1;
    int due = existing?.dueDay ?? 10;
    String icon = existing?.icon ?? '💳';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Agregar Pago Fijo' : 'Editar Pago Fijo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (ej. Tarjeta BBVA)'),
              ),
              TextField(
                controller: totalCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto total', prefixText: '\$ '),
              ),
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Pago mínimo', prefixText: '\$ '),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: cut,
                      items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                      onChanged: (v) => cut = v!,
                      hint: const Text('Día de corte'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: due,
                      items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                      onChanged: (v) => due = v!,
                      hint: const Text('Día de vencimiento'),
                    ),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: icon,
                items: const [
                  DropdownMenuItem(value: '💳', child: Text('💳 Tarjeta')),
                  DropdownMenuItem(value: '🏦', child: Text('🏦 Préstamo')),
                  DropdownMenuItem(value: '📱', child: Text('📱 Servicio')),
                ],
                onChanged: (v) => icon = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final total = double.tryParse(totalCtrl.text.replaceAll(',', '.')) ?? 0;
              final min = double.tryParse(minCtrl.text.replaceAll(',', '.')) ?? 0;
              if (nameCtrl.text.isEmpty || total <= 0 || min <= 0) return;
              final payment = FixedPayment(name: nameCtrl.text, totalAmount: total, minimumPayment: min, cutDay: cut, dueDay: due, icon: icon);
              if (existing == null) {
                provider.addFixedPayment(payment);
              } else {
                provider.updateFixedPayment(existing.key, payment);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}