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
          appBar: AppBar(title: const Text('Pagos Fijos y Tarjetas'), backgroundColor: Colors.deepPurple[100]),
          body: provider.fixedPayments.isEmpty
              ? const Center(child: Text('Sin pagos fijos.\nToca + para agregar', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.fixedPayments.length,
                  itemBuilder: (context, i) {
                    final p = provider.fixedPayments[i];
                    final overdue = _isOverdue(p);
                    return Card(
                      color: overdue ? Colors.red.withOpacity(0.1) : null,
                      child: ListTile(
                        leading: Text(p.icon, style: const TextStyle(fontSize: 40)),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Deuda: \$${p.totalAmount.toStringAsFixed(2)}'),
                          Text('Mínimo: \$${p.minimumPayment.toStringAsFixed(2)}'),
                          Text('Corte: ${p.cutDay} | Pago: ${p.dueDay}'),
                          if (overdue) const Text('¡VENCIDO!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ]),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, provider, p.key)),
                        onTap: () => _showEditDialog(context, provider, p),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(backgroundColor: Colors.deepPurple, child: const Icon(Icons.add), onPressed: () => _showEditDialog(context, provider)),
        );
      },
    );
  }

  bool _isOverdue(FixedPayment p) {
    final now = DateTime.now();
    final due = DateTime(now.year, now.month, p.dueDay);
    return due.isBefore(now) && DateTime(now.year, now.month + 1, p.dueDay).isAfter(now);
  }

  void _confirmDelete(BuildContext context, FinanceProvider provider, dynamic key) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { provider.deleteFixedPayment(key); Navigator.pop(ctx); }, child: const Text('Sí')),
      ],
    ));
  }

  void _showEditDialog(BuildContext context, FinanceProvider provider, [FixedPayment? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final totalCtrl = TextEditingController(text: existing?.totalAmount.toStringAsFixed(2) ?? '');
    final minCtrl = TextEditingController(text: existing?.minimumPayment.toStringAsFixed(2) ?? '');
    int cut = existing?.cutDay ?? 15;
    int due = existing?.dueDay ?? 10;
    String icon = existing?.icon ?? '💳';
    final icons = ['💳', '🏠', '💡', '📺', '📱', '🌐', '🚗', '🏥', '🛒', '🎓'];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setStateDialog) => AlertDialog(
      title: Text(existing == null ? 'Nuevo pago' : 'Editar'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
        TextField(controller: totalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto total')),
        TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pago mínimo')),
        Row(children: [
          Expanded(child: DropdownButton<int>(value: cut, hint: const Text('Corte'), items: List.generate(31, (i) => DropdownMenuItem(value: i+1, child: Text('Día ${i+1}'))), onChanged: (v) => setStateDialog(() => cut = v!))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButton<int>(value: due, hint: const Text('Pago'), items: List.generate(31, (i) => DropdownMenuItem(value: i+1, child: Text('Día ${i+1}'))), onChanged: (v) => setStateDialog(() => due = v!))),
        ]),
        const Text('Icono'), Wrap(children: icons.map((ic) => GestureDetector(onTap: () => setStateDialog(() => icon = ic), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: icon == ic ? Colors.deepPurple : Colors.grey)), child: Text(ic, style: const TextStyle(fontSize: 32))))).toList()),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () {
          final total = double.tryParse(totalCtrl.text.replaceAll(',', '.')) ?? 0;
          final min = double.tryParse(minCtrl.text.replaceAll(',', '.')) ?? 0;
          if (nameCtrl.text.isEmpty || total <= 0 || min <= 0) return;
          final payment = FixedPayment(name: nameCtrl.text, totalAmount: total, minimumPayment: min, cutDay: cut, dueDay: due, icon: icon);
          existing == null ? provider.addFixedPayment(payment) : provider.updateFixedPayment(existing.key, payment);
          Navigator.pop(ctx);
        }, child: const Text('Guardar')),
      ],
    )));
  }
}