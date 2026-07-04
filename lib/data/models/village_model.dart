class VillageModel {
  final String? id; // Supabase ID (UUID)
  final String businessId;
  final String salespersonId;
  final String name;
  final String? notes;
  final String status;
  final String localId;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  VillageModel({
    this.id,
    required this.businessId,
    required this.salespersonId,
    required this.name,
    this.notes,
    this.status = 'active',
    required this.localId,
    this.syncStatus = 'synced',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory VillageModel.fromMap(Map<String, dynamic> map) {
    return VillageModel(
      id: map['id'],
      businessId: map['business_id'],
      salespersonId: map['salesperson_id'],
      name: map['name'],
      notes: map['notes'],
      status: map['status'] ?? 'active',
      localId: map['local_id'] ?? map['id'] ?? '',
      syncStatus: map['sync_status'] ?? 'synced',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'business_id': businessId,
      'salesperson_id': salespersonId,
      'name': name,
      'notes': notes,
      'status': status,
      'local_id': localId,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
    if (id != null) {
      map['server_id'] = id;
    }
    return map;
  }
}
