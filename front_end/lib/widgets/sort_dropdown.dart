import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class SortDropdown extends StatefulWidget {
  final ValueChanged<ProductSort> onSortChanged;
  final VoidCallback onOrderToggled;

  const SortDropdown({
    super.key,
    required this.onSortChanged,
    required this.onOrderToggled,
  });

  @override
  State<SortDropdown> createState() => _SortDropdownState();
}

class _SortDropdownState extends State<SortDropdown> {
  ProductSort? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        // Initialize selected value if not set
        _selectedValue ??= provider.currentSort;

        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ProductSort>(
                initialValue: _selectedValue,
                decoration: InputDecoration(
                  labelText: 'Sort by',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: [
                  DropdownMenuItem<ProductSort>(
                    value: ProductSort.price,
                    child: const Text('Price'),
                  ),
                  DropdownMenuItem<ProductSort>(
                    value: ProductSort.stock,
                    child: const Text('Stock'),
                  ),
                ],
                onChanged: (ProductSort? value) {
                  if (value != null) {
                    setState(() {
                      _selectedValue = value;
                    });
                    widget.onSortChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: widget.onOrderToggled,
              icon: Icon(
                provider.sortOrder == SortOrder.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
              tooltip: provider.sortOrder == SortOrder.ascending
                  ? 'Ascending'
                  : 'Descending',
            ),
          ],
        );
      },
    );
  }
}
