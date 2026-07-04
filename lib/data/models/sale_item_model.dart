class SaleItemModel {
  final String localId;
  final String? serverId;
  final String saleLocalId;
  final String productId;
  final String variantId;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final String syncStatus;

  SaleItemModel({
    required this.localId,
    this.serverId,
    required this.saleLocalId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.syncStatus = 'pending_sync',
  });

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      localId: map['local_id'],
      serverId: map['server_id'],
      saleLocalId: map['sale_local_id'],
      productId: map['product_id'],
      variantId: map['variant_id'],
      quantity: (map['quantity'] ?? 0).toDouble(),
      unitPrice: (map['unit_price'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      syncStatus: map['sync_status'] ?? 'pending_sync',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'sale_local_id': saleLocalId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'sync_status': syncStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
