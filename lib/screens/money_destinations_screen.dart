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
        // Usar StreamBuilder para actualizaciones automáticas
        return StreamBuilder<bool>(
          stream: provider.refreshStream,
          initialData: true,
          builder: (context, snapshot) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Destinos de Dinero'),
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
              body: provider.moneyDestinations.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Agrega personas, cuentas o ahorros donde distribuirás tu dinero\n\nToca el botón + para agregar',
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
                        itemCount: provider.moneyDestinations.length,
                        itemBuilder: (context, i) {
                          final dest = provider.moneyDestinations[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[50],
                              child: Text(dest.icon, style: const TextStyle(fontSize: 20)),
                            ),
                            title: Text(
                              dest.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '\$${dest.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, color: Colors.green),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditDialog(context, provider, dest),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(context, provider, dest),
                                ),
                              ],
                            ),
                            onTap: () => _showEditDialog(context, provider, dest),
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

  void _showEditDialog(
    BuildContext context,
    FinanceProvider provider, [
    MoneyDestination? existing,
  ]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
      text: existing?.amount.toStringAsFixed(2) ?? '',
    );
    String icon = existing?.icon ?? '💰';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Agregar Destino' : 'Editar Destino'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre (ej. Banca, Ahorro, Persona)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto',
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
                DropdownMenuItem(value: '🏦', child: Text('🏦 Banca')),
                DropdownMenuItem(value: '👨', child: Text('👨 Persona')),
                DropdownMenuItem(value: '👩', child: Text('👩 Persona')),
                DropdownMenuItem(value: '💰', child: Text('💰 Ahorro')),
                DropdownMenuItem(value: '💳', child: Text('💳 Tarjeta')),
                DropdownMenuItem(value: '📱', child: Text('📱 App')),
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
              final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0.0;
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa un nombre')),
                );
                return;
              }
              
              if (amount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El monto no puede ser negativo')),
                );
                return;
              }
              
              final dest = MoneyDestination(
                name: name,
                amount: amount,
                icon: icon,
              );
              
              if (existing == null) {
                provider.addMoneyDestination(dest);
              } else {
                provider.updateMoneyDestination(existing.key, dest);
              }
              
              provider.forceFullRefresh(); // Forzar actualización completa
              Navigator.pop(ctx);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(existing == null 
                    ? 'Destino agregado' 
                    : 'Destino actualizado'),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FinanceProvider provider, MoneyDestination dest) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar destino?'),
        content: Text('${dest.icon} ${dest.name} - \$${dest.amount.toStringAsFixed(2)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteMoneyDestination(dest.key);
              provider.forceFullRefresh(); // Forzar actualización completa
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Destino eliminado')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}