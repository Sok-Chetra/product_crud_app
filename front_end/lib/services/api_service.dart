import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000';

  Future<List<Product>> getProducts() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return (data['data'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load products');
    }
  } catch (e) {
    print('❌ Error: $e');
    
    rethrow;
  }
}


  Future<Product> getProduct(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/products/$id'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return Product.fromJson(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load product');
    }
  }

  Future<Product> createProduct(Product product) async {
  print('🔗 [API] Creating product: ${product.toJson()}');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    ).timeout(const Duration(seconds: 10)); // Add timeout

    print('📡 [API] Create Response:');
    print('   Status Code: ${response.statusCode}');
    print('   Headers: ${response.headers}');
    print('   Body: ${response.body}');

    // Handle different success status codes
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      print('📊 [API] Parsed Response: $data');
      
      if (data['success'] == true) {
        print('✅ [API] Product created successfully');
        return Product.fromJson(data['data']);
      } else {
        final errorMsg = data['message'] ?? 'Unknown API error';
        print('❌ [API] API returned error: $errorMsg');
        throw Exception(errorMsg);
      }
    } else {
      // Handle other status codes
      print('❌ [API] HTTP Error ${response.statusCode}');
      final errorBody = response.body;
      print('❌ [API] Error response: $errorBody');
      
      // Try to parse error message from response
      try {
        final errorData = json.decode(errorBody);
        final errorMsg = errorData['message'] ?? 'Failed to create product (HTTP ${response.statusCode})';
        throw Exception(errorMsg);
      } catch (e) {
        throw Exception('Failed to create product. Status: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('❌ [API] Exception in createProduct: $e');
    print('🎯 [API] Exception type: ${e.runtimeType}');
    
    // Provide more specific error messages
    if (e is http.ClientException) {
      throw Exception('Network error: Please check your internet connection');
    } else if (e is TimeoutException) {
      throw Exception('Request timeout: Server took too long to respond');
    } else {
      rethrow;
    }
  }
}

  Future<Product> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/${product.productId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return Product.fromJson(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to update product');
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!data['success']) {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to delete product');
    }
  }
}