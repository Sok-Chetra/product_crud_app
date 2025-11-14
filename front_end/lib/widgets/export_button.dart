import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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
      // Check if there are products to export
      if (provider.products.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No products to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate file name with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String fileName =
          'products_$timestamp.${format == 'pdf' ? 'pdf' : 'csv'}';

      // For macOS, use getDownloadsDirectory as default path
      String? initialDirectory;
      if (Platform.isMacOS) {
        final downloadsDir = await getDownloadsDirectory();
        initialDirectory = downloadsDir?.path;
      }

      // Show file save dialog
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Products',
        fileName: fileName,
        initialDirectory: initialDirectory,
      );

      if (outputFile != null) {
        // Add file extension if not present
        if (!outputFile.endsWith('.${format == 'pdf' ? 'pdf' : 'csv'}')) {
          outputFile += '.${format == 'pdf' ? 'pdf' : 'csv'}';
        }

        // Set exporting state
        provider.setExporting(true);

        // Export based on format
        if (format == 'pdf') {
          await _exportToPdf(provider.allProducts, outputFile);
        } else {
          await _exportToCsv(provider.allProducts, outputFile);
        }

        provider.setExporting(false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Products exported successfully to ${outputFile.split('/').last}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
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
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a page
    final PdfPage page = document.pages.add();

    // Get page size
    final Size pageSize = page.getClientSize();

    // Add title
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 20);
    final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

    page.graphics.drawString(
      'Products Report',
      titleFont,
      bounds: Rect.fromLTWH(0, 20, pageSize.width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Add date
    final String currentDate = DateTime.now().toString().split(' ')[0];
    page.graphics.drawString(
      'Generated on: $currentDate',
      contentFont,
      bounds: Rect.fromLTWH(0, 50, pageSize.width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Create PDF grid
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 4);

    // Set grid style
    grid.style.cellPadding = PdfPaddings(left: 5, top: 5, right: 5, bottom: 5);

    // Add header row
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.style.backgroundBrush = PdfSolidBrush(PdfColor(200, 200, 200));
    headerRow.style.textBrush = PdfSolidBrush(PdfColor(0, 0, 0));
    headerRow.style.font = PdfStandardFont(
      PdfFontFamily.helvetica,
      12,
      style: PdfFontStyle.bold,
    );

    headerRow.cells[0].value = 'ID';
    headerRow.cells[1].value = 'Product Name';
    headerRow.cells[2].value = 'Price';
    headerRow.cells[3].value = 'Stock';

    // Add data rows
    for (final product in products) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = product.productId.toString();
      row.cells[1].value = product.productName;
      row.cells[2].value = '\$${product.price.toStringAsFixed(2)}';
      row.cells[3].value = product.stock.toString();
    }

    // Calculate grid height and position
    final double gridHeight = grid.rows.count * 20 + 50;
    final double startY = 80;

    // Draw grid
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, startY, pageSize.width, gridHeight),
    );

    // Add summary
    final double totalValue = products.fold(
      0,
      (sum, product) => sum + (product.price * product.stock),
    );
    final String summary =
        'Total Products: ${products.length} | Total Inventory Value: \$${totalValue.toStringAsFixed(2)}';

    page.graphics.drawString(
      summary,
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, startY + gridHeight + 10, pageSize.width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Save document
    final List<int> bytes = await document.save();
    document.dispose();

    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _exportToCsv(List<Product> products, String filePath) async {
    final StringBuffer csv = StringBuffer();

    // Add header
    csv.writeln('ID,Product Name,Price,Stock');

    // Add data rows
    for (final product in products) {
      // Escape product name in case it contains commas or quotes
      final escapedName = product.productName.replaceAll('"', '""');
      csv.writeln(
        '${product.productId},"$escapedName",${product.price},${product.stock}',
      );
    }

    // Add summary
    final double totalValue = products.fold(
      0,
      (sum, product) => sum + (product.price * product.stock),
    );
    csv.writeln();
    csv.writeln(
      'Summary,Total Products: ${products.length},Total Inventory Value: \$${totalValue.toStringAsFixed(2)}',
    );

    final File file = File(filePath);
    await file.writeAsString(csv.toString());
  }
}
