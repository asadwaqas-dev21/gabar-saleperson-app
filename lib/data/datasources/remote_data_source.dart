import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salesperson_app/data/models/village_model.dart';
import 'package:salesperson_app/data/models/customer_model.dart';
import 'package:salesperson_app/data/models/inventory_model.dart';
import 'package:salesperson_app/data/models/sale_model.dart';
import 'package:salesperson_app/data/models/payment_model.dart';

class RemoteDataSource {
  final SupabaseClient client = Supabase.instance.client;

  Future<String> _getSalespersonId() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    final response = await client
        .from('salespersons')
        .select('id')
        .eq('profile_id', userId)
        .single();
    return response['id'] as String;
  }

  Future<Map<String, dynamic>> fetchSalespersonProfile() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await client
        .from('salespersons')
        .select(
          'id, business_id, profile_id, name, phone, address, cnic, profile_pic_url, can_send_sms, can_delete_customers, can_use_offline, profiles!salespersons_profile_id_fkey(email, preferred_language), businesses(name, currency, default_language, receipt_footer)',
        )
        .eq('profile_id', userId)
        .single();

    final profile = response['profiles'] as Map<String, dynamic>?;
    final business = response['businesses'] as Map<String, dynamic>?;
    return {
      'local_id': response['id'],
      'server_id': response['id'],
      'business_id': response['business_id'],
      'profile_id': response['profile_id'],
      'name': response['name'],
      'phone': response['phone'],
      'email': profile?['email'],
      'cnic': response['cnic'],
      'address': response['address'],
      'profile_pic_url': response['profile_pic_url'],
      'business_name': business?['name'],
      'currency': business?['currency'] ?? 'PKR',
      'receipt_footer': business?['receipt_footer'],
      'preferred_language':
          profile?['preferred_language'] ??
          business?['default_language'] ??
          'english',
      'can_send_sms': response['can_send_sms'] == false ? 0 : 1,
      'can_delete_customers': response['can_delete_customers'] == true ? 1 : 0,
      'can_use_offline': response['can_use_offline'] == false ? 0 : 1,
      'last_sync_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, String>> fetchSalespersonContext() async {
    final profile = await fetchSalespersonProfile();
    return {
      'businessId': profile['business_id'] as String,
      'salespersonId': profile['server_id'] as String,
    };
  }

  // --- Villages ---

  Future<List<VillageModel>> fetchVillages() async {
    final salespersonId = await _getSalespersonId();
    final response = await client
        .from('villages')
        .select()
        .eq('salesperson_id', salespersonId);

    return response
        .map<VillageModel>((map) => VillageModel.fromMap(map))
        .toList();
  }

  // --- Customers ---

  Future<List<CustomerModel>> fetchCustomers() async {
    final salespersonId = await _getSalespersonId();
    final response = await client
        .from('customers')
        .select()
        .eq('salesperson_id', salespersonId);

    return response.map<CustomerModel>((map) {
      return CustomerModel.fromMap({
        ...map,
        'village_local_id': map['village_id'],
        'village_server_id': map['village_id'],
      });
    }).toList();
  }

  Future<List<SaleModel>> fetchSales() async {
    final salespersonId = await _getSalespersonId();
    final response = await client
        .from('sales')
        .select('*, customers(local_id)')
        .eq('salesperson_id', salespersonId);

    return response.map<SaleModel>((map) {
      final customer = map['customers'] as Map<String, dynamic>?;
      return SaleModel.fromMap({
        ...map,
        'customer_local_id': customer?['local_id'] ?? map['customer_id'],
        'village_local_id': map['village_id'],
        'server_id': map['id'],
        'local_id': map['local_id'] ?? map['id'],
      });
    }).toList();
  }

  Future<List<PaymentModel>> fetchPayments() async {
    final salespersonId = await _getSalespersonId();
    final response = await client
        .from('payments')
        .select('*, customers(local_id, village_id)')
        .eq('salesperson_id', salespersonId)
        .filter('source_sale_id', 'is', null);

    return response.map<PaymentModel>((map) {
      final customer = map['customers'] as Map<String, dynamic>?;
      return PaymentModel.fromMap({
        ...map,
        'customer_local_id': customer?['local_id'] ?? map['customer_id'],
        'village_local_id': customer?['village_id'] ?? '',
        'sale_local_id': map['source_sale_id'],
        'server_id': map['id'],
        'local_id': map['local_id'] ?? map['id'],
        'updated_at': map['created_at'],
      });
    }).toList();
  }

  // --- Inventory ---

  Future<List<ProductModel>> fetchProducts() async {
    final response = await client.from('products').select();

    return response
        .map<ProductModel>((map) => ProductModel.fromMap(map))
        .toList();
  }

  Future<List<ProductVariantModel>> fetchProductVariants() async {
    final response = await client.from('product_variants').select();

    return response
        .map<ProductVariantModel>((map) => ProductVariantModel.fromMap(map))
        .toList();
  }

  Future<List<SalespersonInventoryModel>> fetchSalespersonInventory() async {
    final salespersonId = await _getSalespersonId();
    final response = await client
        .from('salesperson_inventory')
        .select()
        .eq('salesperson_id', salespersonId);

    return response
        .map<SalespersonInventoryModel>(
          (map) => SalespersonInventoryModel.fromMap(map),
        )
        .toList();
  }

  // --- Sync Engine Push ---

  Future<String> pushCustomer(Map<String, dynamic> customerData) async {
    final response = await client
        .from('customers')
        .insert(customerData)
        .select('id')
        .single();
    return response['id'];
  }

  Future<String> pushSale(Map<String, dynamic> saleData) async {
    final response = await client
        .from('sales')
        .insert(saleData)
        .select('id')
        .single();
    return response['id'];
  }

  Future<String> pushSaleItem(Map<String, dynamic> saleItemData) async {
    final response = await client
        .from('sale_items')
        .insert(saleItemData)
        .select('id')
        .single();
    return response['id'];
  }

  Future<String> pushPayment(Map<String, dynamic> paymentData) async {
    final response = await client
        .from('payments')
        .insert(paymentData)
        .select('id')
        .single();
    return response['id'];
  }

  Future<String> pushInventoryReturn(Map<String, dynamic> returnData) async {
    final response = await client
        .from('inventory_returns')
        .insert(returnData)
        .select('id')
        .single();
    return response['id'];
  }
}
