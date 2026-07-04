class SaleModel {
  final String? id; // Supabase ID (UUID)
  final String businessId;
  final String salespersonId;
  final String customerLocalId;
  final String villageLocalId;
  final double totalAmount;
  final double paidAmount;
  final double previousPending;
  final double newPending;
  final DateTime saleDate;
  final String saleStatus;
  final String localId;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  SaleModel({
    this.id,
    required this.businessId,
    required this.salespersonId,
    required this.customerLocalId,
    required this.villageLocalId,
    required this.totalAmount,
    required this.paidAmount,
    required this.previousPending,
    required this.newPending,
    required this.saleDate,
    this.saleStatus = 'completed',
    required this.localId,
    this.syncStatus = 'pending_sync',
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'],
      businessId: map['business_id'],
      salespersonId: map['salesperson_id'],
      customerLocalId: map['customer_local_id'],
      villageLocalId: map['village_local_id'],
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
      paidAmount: (map['paid_amount'] ?? 0).toDouble(),
      previousPending: (map['previous_pending'] ?? 0).toDouble(),
      newPending: (map['new_pending'] ?? 0).toDouble(),
      saleDate: map['sale_date'] != null ? DateTime.parse(map['sale_date']) : DateTime.now(),
      saleStatus: map['sale_status'] ?? 'completed',
      localId: map['local_id'],
      syncStatus: map['sync_status'] ?? 'pending_sync',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'business_id': businessId,
      'salesperson_id': salespersonId,
      'customer_local_id': customerLocalId,
      'village_local_id': villageLocalId,
      'sale_date': saleDate.toIso8601String(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'previous_pending': previousPending,
      'new_pending': newPending,
      'sale_status': saleStatus,
      'local_id': localId,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) {
      map['server_id'] = id;
    }
    return map;
  }
}
