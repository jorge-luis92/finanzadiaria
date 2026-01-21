import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart' hide TextStyle;
import '../providers/finance_provider.dart';
import '../models/transaction.dart';

class ExportService {
  static Future<void> exportMonthToPDF(
    BuildContext context,
    FinanceProvider provider,
    DateTime month,
  ) async {
    try {
      final transactions = provider.getTransactionsByMonth(
        month.month,
        month.year,
      );

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay transacciones para este mes')),
        );
        return;
      }

      final pdf = pw.Document();

      final dateFormat = DateFormat('dd/MM/yyyy');
      final monthFormat = DateFormat('MMMM yyyy', 'es_MX');

      final saldoActualHoy = provider.getCurrentTotalBalance();

      final totalIngresos = transactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalGastos = transactions
          .where((t) => !t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);

      final netoMes = totalIngresos - totalGastos;

      final saldoFinalMes = saldoActualHoy;
      final saldoInicialMes = saldoFinalMes - netoMes;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pw.Context ctx) => pw.Text(
            'FinanzaDiaria • Estado de Cuenta',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          footer: (pw.Context ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generado: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          build: (pw.Context context) => [
            pw.Center(child: pw.Text('ESTADO DE CUENTA MENSUAL', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800))),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text(monthFormat.format(month).toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('App: FinanzaDiaria', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Generado: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Text('Transacciones: ${transactions.length}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Divider(),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(10)),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard('SALDO INICIAL MES', saldoInicialMes, _createPdfColor(96, 125, 139), 0.48),
                      _buildSummaryCard('INGRESOS DEL MES', totalIngresos, PdfColors.green800, 0.48),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard('GASTOS DEL MES', totalGastos, PdfColors.red800, 0.48),
                      _buildSummaryCard(
                        'SALDO FINAL MES',
                        saldoFinalMes,
                        saldoFinalMes >= 0 ? PdfColors.blue800 : _createPdfColor(255, 152, 0),
                        0.48,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            pw.Text('DETALLE DE TRANSACCIONES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: pw.FixedColumnWidth(55),      // Fecha
                1: pw.FlexColumnWidth(1.8),      // Descripción
                2: pw.FixedColumnWidth(70),      // Categoría
                3: pw.FixedColumnWidth(130),     // Método de Pago - AUMENTADO para que quepa completo
                4: pw.FixedColumnWidth(65),      // Monto
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue700),
                  children: [
                    _tableHeaderCell('Fecha'),
                    _tableHeaderCell('Descripción'),
                    _tableHeaderCell('Categoría'),
                    _tableHeaderCell('Método de Pago'),
                    _tableHeaderCell('Monto'),
                  ],
                ),
                ...transactions.map((t) {
                  final cat = provider.categories[t.categoryIndex];
                  return pw.TableRow(
                    children: [
                      _tableCell(dateFormat.format(t.date), align: pw.TextAlign.center),
                      _tableCell(t.description, softWrap: true),
                      _tableCell(cat.name),
                      _tableCellMethod(_formatPaymentForPDF(t)),  // ← Nueva función para mejor wrap
                      _tableCell(
                        '${t.isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                        align: pw.TextAlign.right,
                        color: t.isIncome ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 25),

            if (totalGastos > 0) ...[
              pw.Text('ANÁLISIS DE GASTOS POR CATEGORÍA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ..._buildCategoryAnalysis(transactions, provider),
              pw.SizedBox(height: 25),
            ],

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(10)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('RESUMEN FINANCIERO DEL MES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  _summaryRow('Saldo al inicio del mes', saldoInicialMes, saldoInicialMes >= 0 ? PdfColors.green800 : PdfColors.red800),
                  _summaryRow('+ Total ingresos', totalIngresos, PdfColors.green800),
                  _summaryRow('- Total gastos', totalGastos, PdfColors.red800),
                  pw.Divider(thickness: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 6),
                  _summaryRow('SALDO FINAL DEL MES', saldoFinalMes, saldoFinalMes >= 0 ? PdfColors.blue800 : PdfColors.orange800, bold: true),
                ],
              ),
            ),

            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text(
                'Generado por FinanzaDiaria • No válido como CFDI',
                style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      );

      final outputDir = await getTemporaryDirectory();
      final filePath = '${outputDir.path}/EstadoCuenta_${monthFormat.format(month).replaceAll(' ', '_')}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Estado de cuenta ${monthFormat.format(month)} - FinanzaDiaria\nSaldo final: \$${saldoFinalMes.toStringAsFixed(2)}',
        subject: 'Estado de Cuenta Mensual',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generado. Elige WhatsApp o donde quieras enviarlo')),
      );
    } catch (e, stack) {
      print('Error PDF: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Nueva función específica para la celda de Método (mejor wrap y fuente ajustada)
  static pw.Widget _tableCellMethod(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 7.8),  // un poquito más pequeña para caber mejor
        softWrap: true,
        maxLines: 3,  // permite hasta 3 líneas si es muy largo
        textAlign: pw.TextAlign.center,
        overflow: pw.TextOverflow.visible,  // evita corte duro
      ),
    );
  }

  // El resto igual que antes (solo copio lo necesario para completitud)
  static pw.Widget _buildSummaryCard(
    String title,
    double amount,
    PdfColor color,
    double widthFactor,
  ) {
    final int colorInt = color.toInt();
    final int r = (colorInt >> 16) & 0xFF;
    final int g = (colorInt >> 8) & 0xFF;
    final int b = colorInt & 0xFF;

    final int lightR = ((r * 0.15) + 240).toInt().clamp(0, 255);
    final int lightG = ((g * 0.15) + 240).toInt().clamp(0, 255);
    final int lightB = ((b * 0.15) + 240).toInt().clamp(0, 255);

    final lightColor = PdfColor.fromInt((0xFF << 24) | (lightR << 16) | (lightG << 8) | lightB);

    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: lightColor,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color, width: 0.8),
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 6),
            pw.Text('\$${amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color), textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );
  }

  static String _formatPaymentForPDF(Transaction t) {
    final parts = <String>[];

    if (t.paidWithCash > 0) {
      parts.add('${t.paidWithCash.toStringAsFixed(0)} efec.');
    }

    if (t.paidWithBanks.isNotEmpty) {
      t.paidWithBanks.forEach((bankName, amt) {
        if (amt > 0) {
          parts.add('${amt.toStringAsFixed(0)} $bankName');
        }
      });
    } else if (t.paidWithBank > 0) {
      parts.add('${t.paidWithBank.toStringAsFixed(0)} banco gen.');
    }

    if (parts.isEmpty) return 'N/A';
    if (parts.length == 1) return parts.first;
    return 'Mixto (${parts.join(' + ')})';
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool softWrap = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, color: color ?? PdfColors.black),
        textAlign: align,
        softWrap: softWrap,
        maxLines: softWrap ? 3 : 1,
      ),
    );
  }

  static pw.Widget _summaryRow(String label, double value, PdfColor color, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            '\$${value.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildCategoryAnalysis(
    List<Transaction> transactions,
    FinanceProvider provider,
  ) {
    final gastos = transactions.where((t) => !t.isIncome).toList();
    if (gastos.isEmpty) return [pw.Text('No hay gastos este mes', style: const pw.TextStyle(fontSize: 10))];

    final Map<String, double> catMap = {};
    for (var t in gastos) {
      final name = provider.categories[t.categoryIndex].name;
      catMap[name] = (catMap[name] ?? 0) + t.amount;
    }

    final total = catMap.values.fold(0.0, (a, b) => a + b);
    final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return [
      pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
        columnWidths: {0: pw.FlexColumnWidth(2), 1: pw.FixedColumnWidth(80), 2: pw.FixedColumnWidth(60)},
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Categoría', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Monto', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('%', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
            ],
          ),
          ...sorted.map((e) {
            final perc = total > 0 ? (e.value / total * 100) : 0.0;
            return pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('\$${e.value.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${perc.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
              ],
            );
          }),
        ],
      ),
    ];
  }

  static PdfColor _createPdfColor(int r, int g, int b) {
    return PdfColor.fromInt(0xFF000000 | (r << 16) | (g << 8) | b);
  }
}