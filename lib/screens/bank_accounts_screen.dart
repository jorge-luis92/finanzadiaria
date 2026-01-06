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
        return Scaffold(
          appBar: AppBar(title: const Text('Cuentas Bancarias')),
          body: provider.bankAccounts.isEmpty
              ? const Center(child: Text('Agrega tus cuentas bancarias para llevar control detallado'))
              : ListView.builder(
                  itemCount: provider.bankAccounts.length,
                  itemBuilder: (context, i) {
                    final account = provider.bankAccounts[i];
                    return ListTile(
                      leading: Text(account.icon, style: const TextStyle(fontSize: 36)),
                      title: Text(account.name),
                      trailing: Text('\$${account.balance.toStringAsFixed(2)}'),
                      onTap: () => _editAccount(context, provider, account),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _editAccount(context, provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _editAccount(BuildContext context, FinanceProvider provider, [BankAccount? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final balanceCtrl = TextEditingController(text: existing?.balance.toStringAsFixed(2) ?? '');
    String icon = existing?.icon ?? '🏦';
    final icons = ['🏦', '💳', '📱', '💵', '🪙', '🏧'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(existing == null ? 'Nueva cuenta' : 'Editar cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. Nu, Bancomer)')),
              TextField(controller: balanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Saldo actual', prefixText: '\$ ')),
              const SizedBox(height: 10),
              Wrap(
                children: icons.map((ic) => GestureDetector(
                  onTap: () => setStateDialog(() => icon = ic),
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: icon == ic ? Colors.blue : Colors.grey)), child: Text(ic, style: const TextStyle(fontSize: 32))),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final balance = double.tryParse(balanceCtrl.text.replaceAll(',', '.')) ?? 0.0;
                if (nameCtrl.text.isEmpty || balance < 0) return;
                final account = BankAccount(name: nameCtrl.text.trim(), balance: balance, icon: icon);
                if (existing == null) {
                  provider.addBankAccount(account);
                } else {
                  provider.updateBankAccount(existing.key, account);
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