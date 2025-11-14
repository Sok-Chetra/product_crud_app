import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Product> _allFilteredProducts = [];
  bool _isLoading = false;
  String _error = '';

  // Search
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Sorting
  ProductSort _currentSort = ProductSort.price;
  SortOrder _sortOrder = SortOrder.ascending;

  // Pagination
  final int _pageSize = 6;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Export
  bool _isExporting = false;

  // Getters
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
      _resetAndApplyFilters();
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
    _resetPagination();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
  }

  // Sort products
  void sortProducts(ProductSort sortBy, {SortOrder? order}) {
    _currentSort = sortBy;
    _sortOrder = order ?? _sortOrder;
    _resetPagination();
    _applyFilters();
  }

  // Toggle sort order
  void toggleSortOrder() {
    _sortOrder = _sortOrder == SortOrder.ascending
        ? SortOrder.descending
        : SortOrder.ascending;
    _resetPagination();
    _applyFilters();
  }

  // Load more products for pagination
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;

    // Apply filters without resetting the current displayed items
    _applyFiltersForLoadMore();

    _isLoadingMore = false;
    notifyListeners();
  }

  // Apply filters for initial load, search, sort
  void _applyFilters() {
    List<Product> result = List.from(_products);

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

    // Store complete filtered list
    _allFilteredProducts = result;

    // Get paginated slice
    final totalItems = _allFilteredProducts.length;
    final endIndex = (_currentPage + 1) * _pageSize;
    final actualEndIndex = endIndex.clamp(0, totalItems);

    _filteredProducts = _allFilteredProducts.sublist(0, actualEndIndex);
    _hasMore = actualEndIndex < totalItems;

    notifyListeners();
  }

  // Apply filters for load more - preserves existing items
  void _applyFiltersForLoadMore() {
    List<Product> result = List.from(_products);

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

    // Store complete filtered list
    _allFilteredProducts = result;

    // Get paginated slice - but don't replace the existing list
    final totalItems = _allFilteredProducts.length;
    final endIndex = (_currentPage + 1) * _pageSize;
    final actualEndIndex = endIndex.clamp(0, totalItems);

    // Only update if we have new items to add
    if (actualEndIndex > _filteredProducts.length) {
      _filteredProducts = _allFilteredProducts.sublist(0, actualEndIndex);
    }

    _hasMore = actualEndIndex < totalItems;

    notifyListeners();
  }

  // Reset and apply filters
  void _resetAndApplyFilters() {
    _resetPagination();
    _applyFilters();
  }

  // Reset pagination
  void _resetPagination() {
    _currentPage = 0;
    _hasMore = true;
  }

  // Sort products
  List<Product> _sortProducts(List<Product> products) {
    final sortedProducts = List<Product>.from(products);

    sortedProducts.sort((a, b) {
      int comparison;
      switch (_currentSort) {
        case ProductSort.price:
          comparison = a.price.compareTo(b.price);
          break;
        case ProductSort.stock:
          comparison = a.stock.compareTo(b.stock);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return sortedProducts;
  }

  // Clear search
  void clearSearch() {
    _searchController?.clear();
    _searchQuery = '';
    _resetAndApplyFilters();
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
      _resetAndApplyFilters();
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
      _resetAndApplyFilters();
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
      _resetAndApplyFilters();
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

  // For search controller cleanup
  TextEditingController? _searchController;
  void setSearchController(TextEditingController controller) {
    _searchController = controller;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

enum ProductSort { price, stock }

enum SortOrder { ascending, descending }
