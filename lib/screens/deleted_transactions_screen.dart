import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class DeletedTransactionsScreen extends StatelessWidget {
  const DeletedTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    provider.loadDeletedTransactions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones Eliminadas'),
        backgroundColor: Colors.grey[800],
      ),
      body: provider.deletedTransactions.isEmpty
          ? const Center(
              child: Text(
                'No hay transacciones eliminadas',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.deletedTransactions.length,
              itemBuilder: (context, i) {
                final del = provider.deletedTransactions[i];
                final cat = provider.categories[del.categoryIndex];
                return Card(
                  color: Colors.grey[900],
                  child: ListTile(
                    leading: Text(cat.icon, style: const TextStyle(fontSize: 36)),
                    title: Text(del.description.isEmpty ? cat.name : del.description, style: const TextStyle(color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Original: ${provider.dateFormat.format(del.originalDate)}', style: const TextStyle(color: Colors.grey)),
                        Text('Eliminada: ${provider.dateFormat.format(del.deletedAt)} a las ${del.deletedAt.hour}:${del.deletedAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.redAccent)),
                        Text('Pagado: Efectivo \$${del.paidWithCash.toStringAsFixed(2)} | Banca \$${del.paidWithBank.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange)),
                      ],
                    ),
                    trailing: Text(
                      '${del.isIncome ? '+' : '-'}\$${del.amount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: del.isIncome ? Colors.green : Colors.red),
                    ),
                  ),
                );
              },
            ),
    );
  }
}