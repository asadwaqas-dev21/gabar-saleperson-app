class CustomerModel {
  final String? id; // Supabase ID (UUID)
  final String businessId;
  final String salespersonId;
  final String villageId; // Refers to Supabase UUID or local_id depending on context
  final String name;
  final String? phone;
  final String? houseNumber;
  final String? address;
  final double totalSales;
  final double totalPaid;
  final double totalPending;
  final String? notes;
  final String status;
  final String localId;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    this.id,
    required this.businessId,
    required this.salespersonId,
    required this.villageId,
    required this.name,
    this.phone,
    this.houseNumber,
    this.address,
    this.totalSales = 0,
    this.totalPaid = 0,
    this.totalPending = 0,
    this.notes,
    this.status = 'active',
    required this.localId,
    this.syncStatus = 'synced',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      businessId: map['business_id'],
      salespersonId: map['salesperson_id'],
      villageId: map['village_local_id'] ?? map['village_id'] ?? '',
      name: map['name'],
      phone: map['phone'],
      houseNumber: map['house_number'],
      address: map['address'],
      totalSales: (map['total_sales'] ?? 0).toDouble(),
      totalPaid: (map['total_paid'] ?? 0).toDouble(),
      totalPending: (map['total_pending'] ?? 0).toDouble(),
      notes: map['notes'],
      status: map['status'] ?? 'active',
      localId: map['local_id'] ?? map['id'] ?? '',
      syncStatus: map['sync_status'] ?? 'synced',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'business_id': businessId,
      'salesperson_id': salespersonId,
      'village_local_id': villageId,
      'name': name,
      'phone': phone,
      'house_number': houseNumber,
      'address': address,
      'total_sales': totalSales,
      'total_paid': totalPaid,
      'total_pending': totalPending,
      'notes': notes,
      'status': status,
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
