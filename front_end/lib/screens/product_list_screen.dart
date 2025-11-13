import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../widgets/search_bar.dart';
import '../widgets/sort_dropdown.dart';
import '../widgets/export_button.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      context.read<ProductProvider>().loadMoreProducts();
    }
  }

  void _onRefresh() async {
    await context.read<ProductProvider>().fetchProducts();
    _refreshController.refreshCompleted();
  }

  void _onSearchChanged(String query) {
    context.read<ProductProvider>().searchProducts(query);
  }

  void _onSortChanged(ProductSort sortBy) {
    context.read<ProductProvider>().sortProducts(sortBy);
  }

  void _toggleSortOrder() {
    context.read<ProductProvider>().toggleSortOrder();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ProductProvider>().clearSearch();
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete "${product.productName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await context.read<ProductProvider>().deleteProduct(
                    product.productId,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete product! ${e.toString()}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: const [ExportButton()],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        enablePullDown: true,
        enablePullUp: false,
        header: const ClassicHeader(
          completeText: 'Refresh completed',
          idleText: 'Pull down to refresh',
          releaseText: 'Release to refresh',
          refreshingText: 'Refreshing...',
        ),
        child: Column(
          children: [
            // Search and Sort Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                  ),
                  const SizedBox(height: 12),
                  SortDropdown(
                    onSortChanged: _onSortChanged,
                    onOrderToggled: _toggleSortOrder,
                  ),
                ],
              ),
            ),

            // Product List
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${provider.error}'),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => provider.fetchProducts(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        provider.products.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.products.length) {
                        return _buildLoadingIndicator(provider);
                      }

                      final product = provider.products[index];
                      return _buildProductItem(product);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          product.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: \$${product.price.toStringAsFixed(2)}'),
            Text('Stock: ${product.stock}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(product: product),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(product),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: provider.isLoadingMore
            ? const CircularProgressIndicator()
            : provider.hasMore
            ? ElevatedButton(
                onPressed: provider.loadMoreProducts,
                child: const Text('Load More'),
              )
            : provider.products.isEmpty
            ? const Text('No products found')
            : const Text('No more products'),
      ),
    );
  }
}
