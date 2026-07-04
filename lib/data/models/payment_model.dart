class PaymentModel {
  final String businessId;
  final String salespersonId;
  final String customerLocalId;
  final String villageLocalId;
  final String? saleLocalId; // If payment is tied to a specific sale
  final double amount;
  final String paymentMethod;
  final String? notes;
  final String localId;
  final String? serverId;
  final String syncStatus;
  final DateTime paymentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.businessId,
    required this.salespersonId,
    required this.customerLocalId,
    required this.villageLocalId,
    this.saleLocalId,
    required this.amount,
    this.paymentMethod = 'cash',
    this.notes,
    required this.localId,
    this.serverId,
    required this.syncStatus,
    required this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      businessId: map['business_id'],
      salespersonId: map['salesperson_id'],
      customerLocalId: map['customer_local_id'],
      villageLocalId: map['village_local_id'],
      saleLocalId: map['source_sale_local_id'] ?? map['sale_local_id'],
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['payment_method'] ?? 'cash',
      notes: map['notes'],
      localId: map['local_id'],
      serverId: map['server_id'],
      syncStatus: map['sync_status'],
      paymentDate: DateTime.parse(map['payment_date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business_id': businessId,
      'salesperson_id': salespersonId,
      'customer_local_id': customerLocalId,
      'village_local_id': villageLocalId,
      'source_sale_local_id': saleLocalId,
      'source_sale_server_id': null,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'local_id': localId,
      'server_id': serverId,
      'sync_status': syncStatus,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
