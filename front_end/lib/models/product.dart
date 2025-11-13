class Product {
  final int productId;
  final String productName;
  final double price;
  final int stock;

  Product({
    required this.productId,
    required this.productName,
    required this.price,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different field name cases
      final productId = json['PRODUCTID'] ?? json['productId'] ?? json['id'];
      final productName =
          json['PRODUCTNAME'] ?? json['productName'] ?? json['name'];
      var price = json['PRICE'] ?? json['price'];
      var stock = json['STOCK'] ?? json['stock'];

      if (productId == null) throw Exception('Missing productId field');
      if (productName == null) throw Exception('Missing productName field');
      if (price == null) throw Exception('Missing price field');
      if (stock == null) throw Exception('Missing stock field');

      // Convert price to double safely
      double parsedPrice;
      if (price is double) {
        parsedPrice = price;
      } else if (price is int) {
        parsedPrice = price.toDouble();
      } else if (price is String) {
        parsedPrice = double.tryParse(price) ?? 0.0;
        if (parsedPrice == 0.0) {}
      } else {
        parsedPrice = 0.0;
        print('⚠️ [Model] Unknown price type: ${price.runtimeType}');
      }

      // Convert stock to int safely
      int parsedStock;
      if (stock is int) {
        parsedStock = stock;
      } else if (stock is String) {
        parsedStock = int.tryParse(stock) ?? 0;
        if (parsedStock == 0) {
          print('⚠️ [Model] Could not parse stock string: "$stock"');
        }
      } else if (stock is double) {
        parsedStock = stock.toInt();
      } else {
        parsedStock = 0;
        print('⚠️ [Model] Unknown stock type: ${stock.runtimeType}');
      }

      // Convert productId to int safely
      int parsedProductId;
      if (productId is int) {
        parsedProductId = productId;
      } else if (productId is String) {
        parsedProductId = int.tryParse(productId) ?? 0;
        if (parsedProductId == 0) {
          print('⚠️ [Model] Could not parse productId string: "$productId"');
        }
      } else {
        parsedProductId = 0;
        print('⚠️ [Model] Unknown productId type: ${productId.runtimeType}');
      }

      final product = Product(
        productId: parsedProductId,
        productName: productName.toString(),
        price: parsedPrice,
        stock: parsedStock,
      );

      print('✅ [Model] Successfully created product: ${product.productName}');
      print(
        '   ID: ${product.productId}, Price: ${product.price}, Stock: ${product.stock}',
      );
      return product;
    } catch (e) {
      print('❌ [Model] Error creating product from JSON: $e');
      print('❌ [Model] JSON was: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'stock': stock,
    };
  }

  Product copyWith({
    int? productId,
    String? productName,
    double? price,
    int? stock,
  }) {
    return Product(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  @override
  String toString() {
    return 'Product{id: $productId, name: $productName, price: $price, stock: $stock}';
  }
}
