import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/bank_account.dart';

class BankAccountsScreen extends StatelessWidget {
  const BankAccountsScreen({super.key});

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
                title: const Text('Cuentas Bancarias'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      provider.forceFullRefresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Datos actualizados'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: provider.bankAccounts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Agrega tus cuentas bancarias para llevar control detallado\n\nToca el botón + para agregar',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        provider.forceFullRefresh();
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        itemCount: provider.bankAccounts.length,
                        itemBuilder: (context, i) {
                          final account = provider.bankAccounts[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo[50],
                                child: Text(
                                  account.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              title: Text(
                                account.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'Saldo: \$${account.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: account.balance >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditDialog(context, provider, account),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(context, provider, account),
                                  ),
                                ],
                              ),
                              onTap: () => _showEditDialog(context, provider, account),
                            ),
                          );
                        },
                      ),
                    ),
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () => _showEditDialog(context, provider),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, FinanceProvider provider, [BankAccount? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: existing?.balance.toStringAsFixed(2) ?? '',
    );
    String icon = existing?.icon ?? '🏦';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Agregar Cuenta' : 'Editar Cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre (ej. BBVA, Santander, Nu)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Saldo actual',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: icon,
              decoration: const InputDecoration(
                labelText: 'Icono',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '🏦', child: Text('🏦 Banco')),
                DropdownMenuItem(value: '💳', child: Text('💳 Tarjeta')),
                DropdownMenuItem(value: '📱', child: Text('📱 App')),
                DropdownMenuItem(value: '💰', child: Text('💰 Efectivo digital')),
                DropdownMenuItem(value: '💎', child: Text('💎 Inversión')), // CORREGIDO
              ],
              onChanged: (v) => icon = v!,
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
              final name = nameCtrl.text.trim();
              final balance = double.tryParse(balanceCtrl.text.replaceAll(',', '.')) ?? 0.0;
              
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa un nombre')),
                );
                return;
              }
              
              if (balance < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El saldo no puede ser negativo')),
                );
                return;
              }
              
              final account = BankAccount(name: name, balance: balance, icon: icon);
              
              if (existing == null) {
                provider.addBankAccount(account);
              } else {
                provider.updateBankAccount(existing.key, account);
              }
              
              provider.forceFullRefresh();
              Navigator.pop(ctx);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(existing == null 
                    ? 'Cuenta agregada' 
                    : 'Cuenta actualizada'),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FinanceProvider provider, BankAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: Text('${account.icon} ${account.name} - Saldo: \$${account.balance.toStringAsFixed(2)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteBankAccount(account.key);
              provider.forceFullRefresh();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cuenta eliminada')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}