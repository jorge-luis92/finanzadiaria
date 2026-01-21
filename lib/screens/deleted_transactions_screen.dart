import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class DeletedTransactionsScreen extends StatelessWidget {
  const DeletedTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        // Carga y notifica cada vez que se reconstruye
        if (provider.deletedTransactions.isEmpty) {
          provider.loadDeletedTransactions();
          provider.notifyListeners();
        }

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
              : RefreshIndicator(
                  onRefresh: () async {
                    provider.loadDeletedTransactions();
                  },
                  child: ListView.builder(
                    itemCount: provider.deletedTransactions.length,
                    itemBuilder: (context, i) {
                      final del = provider.deletedTransactions[i];
                      return ListTile(
                        title: Text(del.description),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha original: ${provider.dateFormat.format(del.date)}',
                            ),
                            Text(
                              'Monto: ${del.isIncome ? '+' : '-'}\$${del.amount.toStringAsFixed(2)}',
                            ),
                            Text(
                              'Eliminada: ${provider.dateFormat.format(del.deletedAt)} a las ${del.deletedAt.hour}:${del.deletedAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            Text(
                              'Pagado: Efectivo \$${del.paidWithCash.toStringAsFixed(2)} | Banca \$${del.paidWithBank.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          tooltip: 'Restaurar transacción',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Restaurar transacción'),
                                content: const Text(
                                  '¿Quieres restaurar esta transacción? Se sumará de nuevo al saldo.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      provider.restoreDeletedTransaction(del);
                                      Navigator.pop(ctx);
                                      provider.updateTotals();

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Transacción restaurada',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: const Text('Restaurar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}
