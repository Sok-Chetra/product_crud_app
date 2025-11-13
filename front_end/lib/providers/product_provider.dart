// import 'package:flutter/foundation.dart';
// import '../models/product.dart';
// import '../services/api_service.dart';

// class ProductProvider with ChangeNotifier {
//   final ApiService _apiService = ApiService();
//   List<Product> _products = [];
//   bool _isLoading = false;
//   String _error = '';

//   List<Product> get products => _products;
//   bool get isLoading => _isLoading;
//   String get error => _error;

//   Future<void> fetchProducts() async {
//     _isLoading = true;
//     _error = '';
//     notifyListeners();

//     try {
//       _products = await _apiService.getProducts();
//       _error = '';
//     } catch (e) {
//       //   _error = e.toString();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> addProduct(Product product) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final newProduct = await _apiService.createProduct(product);
//       _products.add(newProduct);
//       _error = '';
//     } catch (e) {
//       //   _error = e.toString();
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> updateProduct(Product product) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final updatedProduct = await _apiService.updateProduct(product);
//       final index = _products.indexWhere(
//         (p) => p.productId == product.productId,
//       );
//       if (index != -1) {
//         _products[index] = updatedProduct;
//       }
//       _error = '';
//     } catch (e) {
//       //   _error = e.toString();
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> deleteProduct(int productId) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       await _apiService.deleteProduct(productId);
//       _products.removeWhere((p) => p.productId == productId);
//       _error = '';
//     } catch (e) {
//       //   _error = e.toString();
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   void clearError() {
//     _error = '';
//     notifyListeners();
//   }
// }

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _error = '';

  // Search
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Sorting

  ProductSort _currentSort = ProductSort.price;
  SortOrder _sortOrder = SortOrder.ascending;

  // Pagination
  final int _pageSize = 5;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Export
  bool _isExporting = false;

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get error => _error;
  String get searchQuery => _searchQuery;
  ProductSort get currentSort => _currentSort;
  SortOrder get sortOrder => _sortOrder;
  bool get isExporting => _isExporting;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _products = await _apiService.getProducts();
      _error = '';
      _applyFilters(); // Apply initial filters after loading
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Debounced search
  void searchProducts(String query) {
    _searchQuery = query;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 0;
      _hasMore = true;
      _applyFilters();
    });
  }

  // Sort products
  void sortProducts(ProductSort sortBy, {SortOrder? order}) {
    _currentSort = sortBy;
    _sortOrder = order ?? _sortOrder;
    _applyFilters();
  }

  // Toggle sort order
  void toggleSortOrder() {
    _sortOrder = _sortOrder == SortOrder.ascending
        ? SortOrder.descending
        : SortOrder.ascending;
    _applyFilters();
  }

  // Load more products for pagination
  // In product_provider.dart, update the loadMoreProducts method:
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) {
      print(
        '🔄 loadMoreProducts: isLoadingMore=$_isLoadingMore, hasMore=$_hasMore',
      );
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    print('🔄 Loading more products... Current page: $_currentPage');

    // Simulate API delay for pagination
    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;
    _applyFilters(preserveCurrent: true);

    print(
      '🔄 Loaded page $_currentPage. Total products: ${_filteredProducts.length}',
    );
    print('🔄 Has more: $_hasMore');

    _isLoadingMore = false;
    notifyListeners();
  }

  // Apply all filters (search, sort, pagination)
  void _applyFilters({bool preserveCurrent = false}) {
    List<Product> result = _products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (product) => product.productName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    // Apply sorting
    result = _sortProducts(result);

    // Apply pagination
    final startIndex = 0;
    final endIndex = preserveCurrent
        ? ((_currentPage + 1) * _pageSize).clamp(0, result.length)
        : _pageSize.clamp(0, result.length);

    if (preserveCurrent) {
      _filteredProducts = result.sublist(0, endIndex);
    } else {
      _filteredProducts = result.sublist(startIndex, endIndex);
    }

    _hasMore = endIndex < result.length;
    notifyListeners();
  }

  List<Product> _sortProducts(List<Product> products) {
    products.sort((a, b) {
      int comparison;
      switch (_currentSort) {
        case ProductSort.name:
          comparison = a.productName.compareTo(b.productName);
          break;
        case ProductSort.price:
          comparison = a.price.compareTo(b.price);
          break;
        case ProductSort.stock:
          comparison = a.stock.compareTo(b.stock);
          break;
        case ProductSort.id:
          comparison = a.productId.compareTo(b.productId);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return products;
  }

  // Reset to first page
  void resetPagination() {
    _currentPage = 0;
    _hasMore = true;
    _applyFilters();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  // Export methods
  void setExporting(bool exporting) {
    _isExporting = exporting;
    notifyListeners();
  }

  // Product CRUD operations
  Future<void> addProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newProduct = await _apiService.createProduct(product);
      _products.add(newProduct);
      _error = '';
      _applyFilters(); // Re-apply filters after adding
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedProduct = await _apiService.updateProduct(product);
      final index = _products.indexWhere(
        (p) => p.productId == product.productId,
      );
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      _error = '';
      _applyFilters(); // Re-apply filters after updating
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(int productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.deleteProduct(productId);
      _products.removeWhere((p) => p.productId == productId);
      _error = '';
      _applyFilters(); // Re-apply filters after deleting
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Sorting enums
enum ProductSort { name, price, stock, id }

enum SortOrder { ascending, descending }
