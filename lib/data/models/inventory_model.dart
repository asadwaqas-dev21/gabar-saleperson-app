class ProductModel {
  final String id;
  final String businessId;
  final String? categoryId;
  final String name;
  final String? description;
  final String status;

  ProductModel({
    required this.id,
    required this.businessId,
    this.categoryId,
    required this.name,
    this.description,
    required this.status,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      businessId: map['business_id'],
      categoryId: map['category_id'],
      name: map['name'],
      description: map['description'],
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'status': status,
    };
  }
}

class ProductVariantModel {
  final String id;
  final String businessId;
  final String productId;
  final String sizeLabel;
  final String unit;
  final String? sku;
  final double salePrice;
  final String status;

  ProductVariantModel({
    required this.id,
    required this.businessId,
    required this.productId,
    required this.sizeLabel,
    required this.unit,
    this.sku,
    required this.salePrice,
    required this.status,
  });

  factory ProductVariantModel.fromMap(Map<String, dynamic> map) {
    return ProductVariantModel(
      id: map['id'],
      businessId: map['business_id'],
      productId: map['product_id'],
      sizeLabel: map['size_label'],
      unit: map['unit'] ?? 'pcs',
      sku: map['sku'],
      salePrice: (map['sale_price'] ?? 0).toDouble(),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'product_id': productId,
      'size_label': sizeLabel,
      'unit': unit,
      'sku': sku,
      'sale_price': salePrice,
      'status': status,
    };
  }
}

class SalespersonInventoryModel {
  final String id;
  final String businessId;
  final String salespersonId;
  final String productId;
  final String variantId;
  final double quantityReceived;
  final double quantitySold;
  final double quantityReturned;
  final double quantityDamaged;
  final double remainingQuantity;

  SalespersonInventoryModel({
    required this.id,
    required this.businessId,
    required this.salespersonId,
    required this.productId,
    required this.variantId,
    required this.quantityReceived,
    required this.quantitySold,
    required this.quantityReturned,
    required this.quantityDamaged,
    required this.remainingQuantity,
  });

  factory SalespersonInventoryModel.fromMap(Map<String, dynamic> map) {
    return SalespersonInventoryModel(
      id: map['id'],
      businessId: map['business_id'],
      salespersonId: map['salesperson_id'],
      productId: map['product_id'],
      variantId: map['variant_id'],
      quantityReceived: (map['quantity_received'] ?? 0).toDouble(),
      quantitySold: (map['quantity_sold'] ?? 0).toDouble(),
      quantityReturned: (map['quantity_returned'] ?? 0).toDouble(),
      quantityDamaged: (map['quantity_damaged'] ?? 0).toDouble(),
      remainingQuantity: (map['remaining_quantity'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'salesperson_id': salespersonId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity_received': quantityReceived,
      'quantity_sold': quantitySold,
      'quantity_returned': quantityReturned,
      'quantity_damaged': quantityDamaged,
      'remaining_quantity': remainingQuantity,
    };
  }
}
