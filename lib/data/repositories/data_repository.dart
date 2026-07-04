import 'package:salesperson_app/data/datasources/local_data_source.dart';
import 'package:salesperson_app/data/datasources/remote_data_source.dart';
import 'package:salesperson_app/data/models/village_model.dart';
import 'package:salesperson_app/data/models/customer_model.dart';
import 'package:salesperson_app/data/models/sale_model.dart';
import 'package:salesperson_app/data/models/sale_item_model.dart';
import 'package:salesperson_app/data/models/payment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DataRepository {
  final LocalDataSource localDataSource;
  final RemoteDataSource remoteDataSource;
  final _uuid = const Uuid();

  DataRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  // --- Villages ---

  Future<List<VillageModel>> getVillages() async {
    // Read strictly from local DB (Offline First)
    return await localDataSource.getVillages();
  }

  Future<List<Map<String, dynamic>>> getVillageSummaries() async {
    return await localDataSource.getVillageSummaries();
  }

  // --- Customers ---

  Future<List<CustomerModel>> getCustomersByVillage(
    String villageLocalId,
  ) async {
    // Read strictly from local DB
    return await localDataSource.getCustomersByVillage(villageLocalId);
  }

  Future<CustomerModel?> getCustomerByLocalId(String localId) async {
    return await localDataSource.getCustomerByLocalId(localId);
  }

  Future<void> addCustomer({
    required String villageLocalId,
    required String name,
    String? phone,
    String? houseNumber,
    String? address,
  }) async {
    final ids = await _getCurrentUserIds();
    final customer = CustomerModel(
      businessId: ids['businessId']!,
      salespersonId: ids['salespersonId']!,
      villageId:
          villageLocalId, // Note: In a real app we need village_server_id too
      name: name,
      phone: phone,
      houseNumber: houseNumber,
      address: address,
      localId: _uuid.v4(),
      syncStatus: 'pending_sync',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save locally
    await localDataSource.insertCustomer(customer);

    // The background SyncEngine will pick this up and push to Supabase
  }

  // --- Sales ---

  Future<void> addSale({
    required String customerLocalId,
    required String villageLocalId,
    required double totalAmount,
    required double paidAmount,
    required double previousPending,
    required List<Map<String, dynamic>> items,
  }) async {
    final ids = await _getCurrentUserIds();
    final newPending = previousPending + totalAmount - paidAmount;

    final saleLocalId = _uuid.v4();
    final saleStatus = paidAmount <= 0
        ? 'pending_payment'
        : paidAmount < previousPending + totalAmount
        ? 'partial_payment'
        : 'completed';
    final sale = SaleModel(
      businessId: ids['businessId']!,
      salespersonId: ids['salespersonId']!,
      customerLocalId: customerLocalId,
      villageLocalId: villageLocalId,
      saleDate: DateTime.now(),
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      previousPending: previousPending,
      newPending: newPending,
      saleStatus: saleStatus,
      localId: saleLocalId,
      syncStatus: 'pending_sync',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final saleItems = items.map((item) {
      return SaleItemModel(
        localId: _uuid.v4(),
        saleLocalId: saleLocalId,
        productId: item['product_id'],
        variantId: item['variant_id'],
        quantity: item['quantity'],
        unitPrice: item['unit_price'],
        subtotal: item['subtotal'],
      );
    }).toList();

    PaymentModel? salePayment;
    if (paidAmount > 0) {
      salePayment = PaymentModel(
        businessId: ids['businessId']!,
        salespersonId: ids['salespersonId']!,
        customerLocalId: customerLocalId,
        villageLocalId: villageLocalId,
        saleLocalId: saleLocalId,
        amount: paidAmount,
        paymentMethod: 'cash',
        notes: 'Payment received with sale',
        localId: _uuid.v4(),
        syncStatus: 'synced',
        paymentDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    await localDataSource.insertSale(sale, saleItems, payment: salePayment);
  }

  Future<List<SaleModel>> getSalesByCustomer(String customerLocalId) async {
    return await localDataSource.getSalesByCustomer(customerLocalId);
  }

  Future<void> addPayment({
    required String customerLocalId,
    required String villageLocalId,
    required double currentPending,
    required double amount,
    String paymentMethod = 'cash',
    String? notes,
  }) async {
    final ids = await _getCurrentUserIds();
    final payment = PaymentModel(
      businessId: ids['businessId']!,
      salespersonId: ids['salespersonId']!,
      customerLocalId: customerLocalId,
      villageLocalId: villageLocalId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
      localId: _uuid.v4(),
      syncStatus: 'pending_sync',
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await localDataSource.insertPayment(
      payment,
      (currentPending - amount).clamp(0, double.infinity).toDouble(),
    );
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    return await localDataSource.getDashboardStats();
  }

  Future<List<Map<String, dynamic>>> getFollowUps() async {
    return await localDataSource.getFollowUps();
  }

  Future<Map<String, dynamic>?> getSalespersonProfile() async {
    return await localDataSource.getSalespersonProfile();
  }

  Future<void> addInventoryReturn({
    required String productId,
    required String variantId,
    required double quantity,
    String? reason,
  }) async {
    final ids = await _getCurrentUserIds();
    final now = DateTime.now().toIso8601String();
    await localDataSource.insertInventoryReturn({
      'local_id': _uuid.v4(),
      'server_id': null,
      'business_id': ids['businessId']!,
      'salesperson_id': ids['salespersonId']!,
      'product_id': productId,
      'variant_id': variantId,
      'quantity_returned': quantity,
      'return_date': now,
      'reason': reason,
      'sync_status': 'pending_sync',
      'sync_error': null,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<Map<String, String>> _getCurrentUserIds() async {
    final cachedProfile = await localDataSource.getSalespersonProfile();
    if (cachedProfile != null) {
      return {
        'salespersonId': cachedProfile['server_id'] as String,
        'businessId': cachedProfile['business_id'] as String,
      };
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await Supabase.instance.client
        .from('salespersons')
        .select('id, business_id')
        .eq('profile_id', userId)
        .single();

    return {
      'salespersonId': response['id'] as String,
      'businessId': response['business_id'] as String,
    };
  }
}
