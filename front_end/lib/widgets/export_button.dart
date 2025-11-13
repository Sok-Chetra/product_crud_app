import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../providers/product_provider.dart';
import '../models/product.dart';

class ExportButton extends StatelessWidget {
  const ExportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return PopupMenuButton<String>(
          onSelected: (value) => _handleExport(context, value, provider),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Export as PDF'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'csv',
              child: Row(
                children: [
                  Icon(Icons.table_chart, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Export as CSV'),
                ],
              ),
            ),
          ],
          child: provider.isExporting
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.import_export),
        );
      },
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    String format,
    ProductProvider provider,
  ) async {
    try {
      // Generate file name with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String fileName =
          'products_$timestamp.${format == 'pdf' ? 'pdf' : 'csv'}';

      // Show file save dialog
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Products',
        fileName: fileName,
      );

      if (outputFile != null) {
        provider.setExporting(true);

        if (format == 'pdf') {
          await _exportToPdf(provider.allProducts, outputFile);
        } else {
          await _exportToCsv(provider.allProducts, outputFile);
        }

        provider.setExporting(false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Products exported successfully to $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // await OpenFile.open(outputFile);
      }
    } catch (e) {
      provider.setExporting(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToPdf(List<Product> products, String filePath) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Add title
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 20);
    page.graphics.drawString(
      'Products Report',
      titleFont,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
    );

    // Create PDF grid
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 4);

    // Add header
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'ID';
    headerRow.cells[1].value = 'Product Name';
    headerRow.cells[2].value = 'Price';
    headerRow.cells[3].value = 'Stock';

    // Add rows
    for (final product in products) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = product.productId.toString();
      row.cells[1].value = product.productName;
      row.cells[2].value = '\$${product.price.toStringAsFixed(2)}';
      row.cells[3].value = product.stock.toString();
    }

    // Draw grid
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
        0,
        60,
        page.getClientSize().width,
        page.getClientSize().height - 60,
      ),
    );

    // Save document
    final File file = File(filePath);
    await file.writeAsBytes(await document.save());
    document.dispose();
  }

  Future<void> _exportToCsv(List<Product> products, String filePath) async {
    final StringBuffer csv = StringBuffer();

    // Add header
    csv.writeln('ID,Product Name,Price,Stock');

    // Add data
    for (final product in products) {
      csv.writeln(
        '${product.productId},"${product.productName}",${product.price},${product.stock}',
      );
    }

    final File file = File(filePath);
    await file.writeAsString(csv.toString());
  }
}
