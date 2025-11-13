import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        productId: 0,
        productName: _nameController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
      );

      try {
        await context.read<ProductProvider>().addProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add product! Something went wrong.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }

                  // Handle negative zero and regular parsing
                  final price = double.tryParse(value);
                  if (price == null) {
                    return 'Please enter a valid number';
                  }

                  // Check for negative zero or any negative value
                  if (price.isNegative || price <= 0) {
                    return 'Please enter a positive price';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }

                  if (value == '-0' || value.startsWith('-')) {
                    return 'Please enter a non-negative stock quantity';
                  }

                  // Handle negative zero and regular parsing
                  final stock = int.tryParse(value);
                  if (stock == null) {
                    return 'Please enter a valid whole number';
                  }

                  // Check for negative values (including -0 which becomes 0 in int)
                  if (stock < 0) {
                    return 'Please enter a non-negative stock quantity';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitForm,
                    child: provider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Add Product'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
